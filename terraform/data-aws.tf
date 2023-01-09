## AWS Data
data "aws_availability_zones" "rke2" {
  state = "available"
}

data "aws_caller_identity" "rke2" {
}

data "aws_partition" "rke2" {
}

## AMIs
data "aws_ami" "rke2" {
  for_each    = var.amis
  most_recent = true
  owners      = [each.value.aws_partition_owner[data.aws_partition.rke2.partition]]
  filter {
    name   = "name"
    values = [each.value.name]
  }
}
