#!/bin/bash

echo "INFO: labeling node"

until /var/lib/rancher/rke2/bin/kubectl --server "$RKE2_URL" --kubeconfig /etc/rancher/rke2/rke2.yaml \
    label --overwrite=true node "$(hostname -f)" \
    kubernetes.io/arch="$ARCH" \
    kubernetes.io/cluster="$PREFIX"-"$SUFFIX" \
    kubernetes.io/node-group="$NODEGROUP" \
    node.kubernetes.io/ami-type="$AMI_TYPE" \
    node.kubernetes.io/instance-type="$INSTANCE_TYPE" \
    topology.kubernetes.io/region="$REGION" \
    topology.kubernetes.io/zone="$AWS_AZ"
do
    echo "INFO: unable to label, retrying"
    sleep 3
    resolvectl flush-caches
done
