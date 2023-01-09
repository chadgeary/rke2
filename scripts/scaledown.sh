#!/bin/bash

# various vars - the curl to 169.254.169.254 are AWS instance-specific API facts
HOOKRESULT='CONTINUE'
AWS_METADATA_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -H "X-aws-ec2-metadata-token: $AWS_METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/.$//')
SLEEP_SECONDS=90

# drain
echo "INFO: draining"
/var/lib/rancher/rke2/bin/kubectl --server "$RKE2_URL" --kubeconfig /etc/rancher/rke2/rke2.yaml \
    drain "$(hostname -f)" \
    --grace-period=$SLEEP_SECONDS \
    --ignore-daemonsets \
    --force

sleep $SLEEP_SECONDS

# rke2 killall
echo "INFO: rke2-killall.sh"
/usr/local/bin/rke2-killall.sh

# delete node
echo "INFO: kubectl delete node"
/var/lib/rancher/rke2/bin/kubectl --server "$RKE2_URL" --kubeconfig /etc/rancher/rke2/rke2.yaml \
    delete node "$(hostname -f)"

# notify aws complete
echo "INFO: aws autoscaling complete-lifecycle-action"
aws autoscaling complete-lifecycle-action \
  --lifecycle-hook-name "$LIFECYCLEHOOKNAME" \
  --auto-scaling-group-name "$ASGNAME" \
  --lifecycle-action-result $HOOKRESULT \
  --instance-id "$INSTANCE_ID" \
  --region "$REGION"
