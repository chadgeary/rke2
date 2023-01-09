## Project
# Labels attached to resource names, use a short lower alphanumeric string
# If suffix is empty, a random two character suffix is generated
prefix = "rke2"
suffix = ""

## AWS
profile = "default"
region  = "us-east-1"

## Networking
vpc_cidr      = "172.16.0.0/16" # vpc_cidr is split across availability zones, minimum 2
cluster_cidr  = "172.17.0.0/16" # assigned to rke2 pods and services
azs           = 2               # aws azs
nat_gateways  = true            # permits internet egress
vpc_endpoints = false           # required if nat_gateways = false, optional otherwise.

## Logs
# codebuild, lambda
log_retention_in_days = 30 # 0 = never expire

## Secrets
# Encrypted SSM parameters, available to EC2 instances
# The path to each value is /${local.prefix}-${local.suffix}/<key>
# Warn: Keep this file and the terraform state file secure!
secrets = {
  PLATFORM_TOKEN = "Change_me_please_1"
}

## AMIs
# FIPS @ https://aws.amazon.com/marketplace/pp/prodview-l2hkkatnodedk
# Requires AWS License Manager activation @ https://us-east-1.console.aws.amazon.com/license-manager/
amis = {
  fips = {
    name = "ubuntu-pro-fips-server/images/hvm-ssd/ubuntu-focal-20.04-amd64-pro-fips-server-*"
    aws_partition_owner = {
      aws        = "679593333241"
      aws-cn     = ""
      aws-us-gov = "345084742485"
    }
  }
}

## Container Images
# Images cloned to Private ECR via codebuild
# ensure charts.sh tags match
container_images = [
  "amazon/aws-efs-csi-driver:v1.4.8",
  "registry.k8s.io/provider-aws/cloud-controller-manager:v1.25.1",
  "ghcr.io/zcube/bitnami-compat/external-dns:0",
]

## Node groups via ASGs
# one group must be named 'control-plane' with a min of 1
nodegroups = {
  control-plane = {
    ami = "fips"
    scaling_count = {
      min = 1
      max = 1
    }
    volume = {
      gb   = 15
      type = "gp3"
    }
    instance_types = ["t3a.large", "t3.large"]
  }
  worker1 = {
    ami = "fips"
    scaling_count = {
      min = 0
      max = 0
    }
    volume = {
      gb   = 30
      type = "gp3"
    }
    instance_types = ["t3a.large", "t3.large"]
  }
}

## lambda_to_s3
# each represents a lambda invocation for downloading a file to s3 (if not exists)
# awscli @ https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
# helm @ https://github.com/helm/helm/releases
# rke2 @ https://github.com/rancher/rke2/releases
# cloud controller @ https://kubernetes.github.io/cloud-provider-aws/index.yaml
# efs @ https://github.com/kubernetes-sigs/aws-efs-csi-driver/releases
# external-dns @ https://charts.bitnami.com/bitnami/index.yaml
# unzip @ http://us-east-1.ec2.ports.ubuntu.com/ubuntu-ports/pool/main/u/unzip/ & http://us-east-1.ec2.archive.ubuntu.com/ubuntu/pool/main/u/unzip/
lambda_to_s3 = {
  # awscli
  AWSCLIV2_X86_64 = {
    url    = "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
    prefix = "scripts/awscli-exe-linux-x86_64.zip"
  }
  # helm
  HELM_X86_64 = {
    url    = "https://get.helm.sh/helm-v3.10.3-linux-amd64.tar.gz"
    prefix = "data/downloads/rke2/helm-x86_64.tar.gz"
  }
  # rke2
  PLATFORM_BIN_X86_64 = {
    url    = "https://github.com/rancher/rke2/releases/download/v1.23.15%2Brke2r1/rke2.linux-amd64"
    prefix = "data/downloads/rke2/rke2-x86_64"
  }
  PLATFORM_TAR_X86_64 = {
    url    = "https://github.com/rancher/rke2/releases/download/v1.23.15%2Brke2r1/rke2-images-canal.linux-amd64.tar.gz"
    prefix = "data/downloads/rke2/rke2-images-canal.linux-amd64.tar.gz"
  }
  PLATFORM_INSTALL = {
    url    = "https://raw.githubusercontent.com/rancher/rke2/master/install.sh"
    prefix = "scripts/install.sh"
  }
  # charts
  AWS_CLOUD_CONTROLLER = {
    url    = "https://github.com/kubernetes/cloud-provider-aws/releases/download/helm-chart-aws-cloud-controller-manager-0.0.7/aws-cloud-controller-manager-0.0.7.tgz"
    prefix = "data/downloads/charts/aws-cloud-controller-manager.tgz"
  }
  AWS_EFS_CSI_DRIVER = {
    url    = "https://github.com/kubernetes-sigs/aws-efs-csi-driver/releases/download/helm-chart-aws-efs-csi-driver-2.3.5/aws-efs-csi-driver-2.3.5.tgz"
    prefix = "data/downloads/charts/aws-efs-csi-driver.tgz"
  }
  EXTERNAL_DNS = {
    url    = "https://charts.bitnami.com/bitnami/external-dns-6.12.1.tgz"
    prefix = "data/downloads/charts/external-dns.tgz"
  }
  # packages
  UNZIP_X86_64 = {
    url    = "http://us-east-1.ec2.archive.ubuntu.com/ubuntu/pool/main/u/unzip/unzip_6.0-25ubuntu1.1_amd64.deb"
    prefix = "scripts/unzip-x86_64.deb"
  }
}
