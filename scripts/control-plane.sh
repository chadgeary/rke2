#!/bin/bash

set -x
echo "INFO: determining if first control-plane instance"
FIRST_INSTANCE_PARAMETER=$(aws --region "$REGION" ssm get-parameter --with-decryption --name /"$PREFIX"-"$SUFFIX"/FIRST_INSTANCE_ID --query Parameter.Value --output text)
FIRST_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=control-plane.$PREFIX-$SUFFIX.internal" "Name=instance-state-name,Values=running" --query 'sort_by(Reservations[].Instances[], &LaunchTime)[0].[InstanceId]' --output text)
if [ "$FIRST_INSTANCE_PARAMETER" == "unset" ] && [ "$INSTANCE_ID" == "$FIRST_INSTANCE_ID" ]; then
    echo "INFO: SSM parameter is unset and matching FIRST_INSTANCE_ID, will cluster-init"
    unset RKE2_URL
    aws --region "$REGION" ssm put-parameter --name /"$PREFIX"-"$SUFFIX"/FIRST_INSTANCE_ID --value "$INSTANCE_ID" --overwrite
    CONTROLPLANE_INIT_ARG="--cluster-init"
    export CONTROLPLANE_INIT_ARG
else
    echo "INFO: SSM parameter is set or not matching FIRST_INSTANCE_ID, skipping cluster-init"
    CONTROLPLANE_INIT_ARG="--server $RKE2_URL"
    export CONTROLPLANE_INIT_ARG
fi

echo "INFO: installing rke2"

"$PLATFORM_INSTALL_PATH"/"$PLATFORM_INSTALL_FILE" server $CONTROLPLANE_INIT_ARG \
    --resolv-conf=/etc/rancher/rke2/resolv.conf \
    --kubelet-arg=provider-id=aws:///$AWS_AZ/$INSTANCE_ID \
    --kube-apiserver-arg=api-audiences=$PREFIX-$SUFFIX \
    --kube-apiserver-arg=service-account-issuer=https://s3.$REGION.amazonaws.com/$PREFIX-$SUFFIX-public/oidc \
    --kube-apiserver-arg=service-account-jwks-uri=https://s3.$REGION.amazonaws.com/$PREFIX-$SUFFIX-public/oidc/openid/v1/jwks \
    --cluster-cidr=$POD_CIDR \
    --service-cidr=$SVC_CIDR \
    --cluster-dns=$KUBEDNS_IP \
    --disable-cloud-controller \
    --node-label=node.kubernetes.io/instance-type=$INSTANCE_TYPE \
    --node-taint=node-role.kubernetes.io/control-plane:NoSchedule \
    --node-taint=node.cilium.io/agent-not-ready:NoSchedule \
    --tls-san=control-plane.$PREFIX-$SUFFIX.internal \
    --node-ip $INSTANCE_IP \
    --advertise-address $INSTANCE_IP

systemctl start rke2-server.service

echo "INFO: copying /etc/rancher/rke2/rke2.yaml to s3://"$PREFIX"-"$SUFFIX"-private/data/rke2/config"
for i in {1..120}; do
    echo -n "."
    aws --region "$REGION" s3 cp /etc/rancher/rke2/rke2.yaml s3://"$PREFIX"-"$SUFFIX"-private/data/rke2/config && echo "" && break || sleep 1
done

# labels
bash /usr/local/bin/label.sh

# oidc
bash /usr/local/bin/oidc.sh

# ecr
bash /usr/local/bin/ecr.sh

# charts
bash /usr/local/bin/charts.sh
