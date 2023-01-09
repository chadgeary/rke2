#!/bin/bash

# This script runs on all nodes at startup

ARCH=$(uname -m); if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi

# unzip + awscli install
dpkg -i "$PWD"/unzip-"$ARCH".deb
unzip -q -o awscli-exe-linux-"$ARCH".zip
./aws/install --bin-dir /usr/local/bin --install-dir /opt/awscli --update

# add'l vars
AWS_METADATA_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AWS_AZ=$(curl -H "X-aws-ec2-metadata-token: $AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
AWS_ECR_PREFIX="$ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$PREFIX-$SUFFIX"
CHARTS_PATH="/opt/charts"
INSTALL_RKE2_SKIP_DOWNLOAD="true"
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
INSTANCE_IP=$(curl -H "X-aws-ec2-metadata-token: $AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4)
INSTANCE_TYPE=$(curl -H "X-aws-ec2-metadata-token: $AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-type)
K8S_PLATFORM="rke2"
PLATFORM_TOKEN=$(aws --region "$REGION" ssm get-parameter --with-decryption --name /"$PREFIX"-"$SUFFIX"/PLATFORM_TOKEN --query Parameter.Value --output text)
PLATFORM_BIN_PATH="/usr/local/bin"
PLATFORM_BIN_FILE="$K8S_PLATFORM"
PLATFORM_TAR_PATH="/var/lib/rancher/$K8S_PLATFORM/agent/images"
PLATFORM_TAR_FILE="rke2-images-canal.linux-amd64.tar.gz"
PLATFORM_INSTALL_PATH="/usr/local/bin"
PLATFORM_INSTALL_FILE="install.sh"
RKE2_URL="https://control-plane.$PREFIX-$SUFFIX.internal:6443"

# ensure SSM and above vars are exported
export ARCH AMI_TYPE AWS_ADDON_URI AWS_AZ AWS_ECR_PREFIX AWS_METADATA_TOKEN CHARTS_PATH EFS_ID INSTALL_RKE2_SKIP_DOWNLOAD K8S_PLATFORM INSTANCE_ID INSTANCE_IP INSTANCE_TYPE PLATFORM_BIN_FILE PLATFORM_BIN_PATH PLATFORM_INSTALL_FILE PLATFORM_INSTALL_PATH NODEGROUP PLATFORM_TAR_FILE PLATFORM_TAR_PATH PLATFORM_TOKEN RKE2_URL KUBEDNS_IP NAT_GATEWAYS POD_CIDR PREFIX REGION SUFFIX SVC_CIDR VPC_CIDR

# copy scaledown.sh
cp scaledown.sh /usr/local/bin/scaledown.sh

# directories
mkdir -p /etc/rancher/$K8S_PLATFORM /var/lib/rancher/$K8S_PLATFORM/agent/images /var/lib/rancher/$K8S_PLATFORM/agent/etc/containerd
chmod 750 /etc/rancher/$K8S_PLATFORM /var/lib/rancher/$K8S_PLATFORM/agent/images /var/lib/rancher/$K8S_PLATFORM/agent/etc/containerd

# ec2 vpc r53 nameserver
echo "nameserver 169.254.169.253" > /etc/rancher/$K8S_PLATFORM/resolv.conf

# ec2 ip to /etc/hosts https://github.com/k3s-io/k3s/issues/163#issuecomment-469882207
if grep --quiet "$INSTANCE_IP" /etc/hosts; then
    tee -a /etc/hosts << EOM

# platform
$INSTANCE_IP localhost
$INSTANCE_IP $(hostname)

EOM
fi

# platform binary
if [ -f "$PLATFORM_BIN_PATH/$PLATFORM_BIN_FILE" ]; then
    echo "INFO: bin exists, skipping"
else
    aws --region "$REGION" s3 cp --quiet s3://"$PREFIX"-"$SUFFIX"-private/data/downloads/$K8S_PLATFORM/"$PLATFORM_BIN_FILE"-"$ARCH" "$PLATFORM_BIN_PATH"/"$PLATFORM_BIN_FILE" --quiet
    chmod +x "$PLATFORM_BIN_PATH"/"$PLATFORM_BIN_FILE"
fi

# platform tar
if [ -f "$PLATFORM_TAR_PATH/$PLATFORM_TAR_FILE".tar ]; then
    echo "INFO: tar exists, skipping"
else
    aws --region "$REGION" s3 cp --quiet s3://"$PREFIX"-"$SUFFIX"-private/data/downloads/$K8S_PLATFORM/"$PLATFORM_TAR_FILE" "$PLATFORM_TAR_PATH"/"$PLATFORM_TAR_FILE" --quiet
fi

# platform install script
if [ -f "$PLATFORM_INSTALL_PATH/$PLATFORM_INSTALL_FILE" ]; then
    echo "INFO: script exists, skipping"
else
    mkdir -p "$PLATFORM_INSTALL_PATH"
    cp ./install.sh "$PLATFORM_INSTALL_PATH"/"$PLATFORM_INSTALL_FILE"
    chmod +x "$PLATFORM_INSTALL_PATH"/"$PLATFORM_INSTALL_FILE"
fi

# copy sh scripts to /usr/local/bin
for SH_SCRIPT in charts.sh control-plane.sh ecr.sh label.sh oidc.sh worker.sh; do
    cp "$SH_SCRIPT" /usr/local/bin/
    chmod 700 /usr/local/bin/"$SH_SCRIPT"
done

# fips mode
if [ -f "/opt/fips.done" ]; then
    echo "INFO: fips.done exists, skipping"
else
    bash fips.sh
fi
