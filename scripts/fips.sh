#!/bin/bash
echo "INFO: enabling fips-mode via ubuntu pro"

# post-fips-bootstrap.sh
if [ -f /usr/local/bin/post-fips-bootstrap.sh ]; then
    echo "INFO: /usr/local/bin/post-fips-bootstrap.sh exists, skipping"
else
    tee /usr/local/bin/post-fips-bootstrap.sh >/dev/null << EOM 
#!/bin/bash

ARCH=$ARCH
AMI_TYPE=$AMI_TYPE
AWS_ADDON_URI=$AWS_ADDON_URI
EFS_ID=$EFS_ID
PLATFORM_BIN_FILE=$PLATFORM_BIN_FILE
PLATFORM_BIN_PATH=$PLATFORM_BIN_PATH
PLATFORM_INSTALL_FILE=$PLATFORM_INSTALL_FILE
PLATFORM_INSTALL_PATH=$PLATFORM_INSTALL_PATH
NODEGROUP=$NODEGROUP
PLATFORM_TAR_FILE=$PLATFORM_TAR_FILE
PLATFORM_TAR_PATH=$PLATFORM_TAR_PATH
PLATFORM_TOKEN=$PLATFORM_TOKEN
RKE2_URL=$RKE2_URL
KUBEDNS_IP=$KUBEDNS_IP
NAT_GATEWAYS=$NAT_GATEWAYS
POD_CIDR=$POD_CIDR
PREFIX=$PREFIX
REGION=$REGION
SUFFIX=$SUFFIX
SVC_CIDR=$SVC_CIDR
VPC_CIDR=$VPC_CIDR

AWS_METADATA_TOKEN=\$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AWS_AZ=\$(curl -H "X-aws-ec2-metadata-token: \$AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
AWS_ECR_PREFIX="$ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$PREFIX-$SUFFIX"
CHARTS_PATH="/opt/charts"
INSTALL_RKE2_SKIP_DOWNLOAD="true"
INSTANCE_ID=\$(curl -H "X-aws-ec2-metadata-token: \$AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
INSTANCE_IP=\$(curl -H "X-aws-ec2-metadata-token: \$AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4)
INSTANCE_TYPE=\$(curl -H "X-aws-ec2-metadata-token: \$AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-type)
K8S_PLATFORM="rke2"
PLATFORM_TOKEN=\$(aws --region "$REGION" ssm get-parameter --with-decryption --name /"$PREFIX"-"$SUFFIX"/PLATFORM_TOKEN --query Parameter.Value --output text)
PLATFORM_BIN_PATH="/usr/local/bin"
PLATFORM_BIN_FILE="$K8S_PLATFORM"
PLATFORM_TAR_PATH="/var/lib/rancher/$K8S_PLATFORM/agent/images"
PLATFORM_TAR_FILE="rke2-images-canal.linux-amd64.tar.gz"
PLATFORM_INSTALL_PATH="/usr/local/bin"
PLATFORM_INSTALL_FILE="install.sh"
RKE2_URL="https://control-plane.$PREFIX-$SUFFIX.internal:6443"

# ensure SSM and above vars are exported
export ARCH AMI_TYPE AWS_ADDON_URI AWS_AZ AWS_ECR_PREFIX AWS_METADATA_TOKEN CHARTS_PATH EFS_ID INSTALL_RKE2_SKIP_DOWNLOAD K8S_PLATFORM INSTANCE_ID INSTANCE_IP INSTANCE_TYPE PLATFORM_BIN_FILE PLATFORM_BIN_PATH PLATFORM_INSTALL_FILE PLATFORM_INSTALL_PATH NODEGROUP PLATFORM_TAR_FILE PLATFORM_TAR_PATH PLATFORM_TOKEN RKE2_URL KUBEDNS_IP NAT_GATEWAYS POD_CIDR PREFIX REGION SUFFIX SVC_CIDR VPC_CIDR


# exit-standby
if [ -f /opt/fips.done ] && [ ! -f /opt/standby.done ]; then
    echo "INFO: continuing post-fips-bootstrap.sh"

    # exit standby + set desired+1
    aws autoscaling exit-standby \
        --instance-ids "\$INSTANCE_ID" \
        --auto-scaling-group-name "\$PREFIX"-"\$SUFFIX"-"\$NODEGROUP" \
        --region "\$REGION"

    # current minimum
    ASG_MIN=\$(aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names "\$PREFIX"-"\$SUFFIX"-"\$NODEGROUP" \
        --region "\$REGION" \
        --query "AutoScalingGroups[0].MinSize" \
        --output text)

    # set minimum+1
    aws autoscaling update-auto-scaling-group \
        --auto-scaling-group-name "\$PREFIX"-"\$SUFFIX"-"\$NODEGROUP" \
        --region "\$REGION" \
        --min-size \$((ASG_MIN+1))

    touch /opt/standby.done
else
    echo "INFO: found fips.done and standby.done, skipping asg actions"
fi

# install platform
if [ "\$NODEGROUP" == "control-plane" ]; then
    bash /usr/local/bin/control-plane.sh
else
    bash /usr/local/bin/worker.sh
fi

EOM

    chmod 700 /usr/local/bin/post-fips-bootstrap.sh

    tee /etc/systemd/system/post-fips-bootstrap.service >/dev/null << EOM
[Unit]
Description=Executes post-fips-bootstrap.sh
After=network.target
[Service]
ExecStart=/usr/local/bin/post-fips-bootstrap.sh
Type=simple
Restart=no
[Install]
WantedBy=multi-user.target
EOM

echo "INFO: enabling /usr/local/bin/post-fips-bootstrap.sh systemd service"
systemctl daemon-reload
systemctl enable post-fips-bootstrap.service

fi

# ubuntu pro enable fips-updates
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ubuntu-advantage-tools
until pro enable fips-updates --assume-yes;
do
  sleep 1
  pro status
done

# current minimum
ASG_MIN=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$PREFIX"-"$SUFFIX"-"$NODEGROUP" \
  --region "$REGION" \
  --query "AutoScalingGroups[0].MinSize" \
  --output text)

# set minimum-1
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name "$PREFIX"-"$SUFFIX"-"$NODEGROUP" \
  --region "$REGION" \
  --min-size $((ASG_MIN-1))

# enter standby + set desired-1
aws autoscaling enter-standby \
  --auto-scaling-group-name "$PREFIX"-"$SUFFIX"-"$NODEGROUP" \
  --region "$REGION" \
  --should-decrement-desired-capacity \
  --instance-ids "$INSTANCE_ID"

# track on disk
touch /opt/fips.done

# reboot
systemctl reboot
