#!/bin/bash

echo "INFO: running installer ($NODEGROUP/agent)"
INSTALL_RKE2_TYPE=agent
INSTALL_RKE2_EXEC="agent --server $RKE2_URL --kubelet-arg=provider-id=aws:///$AWS_AZ/$INSTANCE_ID --resolv-conf=/etc/rancher/rke2/resolv.conf --node-label=node.kubernetes.io/instance-type=$INSTANCE_TYPE --node-taint=node.cilium.io/agent-not-ready:NoSchedule --node-ip $INSTANCE_IP"
export INSTALL_RKE2_EXEC
"$PLATFORM_INSTALL_PATH"/"$PLATFORM_INSTALL_FILE"

systemctl start rke2-agent.service

echo "INFO: copying kube config from s3"
for i in {1..120}; do
    echo -n "."
    aws --region "$REGION" s3 cp s3://"$PREFIX"-"$SUFFIX"-private/data/rke2/config /etc/rancher/rke2/rke2.yaml && echo "" && break || sleep 1
done
chmod 600 /etc/rancher/rke2/rke2.yaml

# labels
bash /usr/local/bin/label.sh

# ecr
bash /usr/local/bin/ecr.sh
