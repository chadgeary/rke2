# security group for cluster
resource "aws_security_group" "rke2-ec2" {
  name_prefix = "${local.prefix}-${local.suffix}-ec2"
  description = "SG for ${local.prefix}-${local.suffix} ec2"
  vpc_id      = aws_vpc.rke2.id
  tags = {
    Name                                                    = "${local.prefix}-${local.suffix}-ec2"
    "kubernetes.io/cluster/${local.prefix}-${local.suffix}" = "shared"
  }
}

resource "aws_security_group_rule" "rke2-ec2-ingress-self-sg" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  security_group_id        = aws_security_group.rke2-ec2.id
  source_security_group_id = aws_security_group.rke2-ec2.id
}

resource "aws_security_group_rule" "rke2-ec2-egress-self-sg" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  security_group_id        = aws_security_group.rke2-ec2.id
  source_security_group_id = aws_security_group.rke2-ec2.id
}

resource "aws_security_group_rule" "rke2-ec2-ingress-self-lb-private" {
  type              = "ingress"
  from_port         = "6443"
  to_port           = "6443"
  protocol          = "tcp"
  security_group_id = aws_security_group.rke2-ec2.id
  cidr_blocks       = [for net in aws_subnet.rke2-private : net.cidr_block]
}

resource "aws_security_group_rule" "rke2-ec2-egress-self-lb-private" {
  type              = "egress"
  from_port         = "6443"
  to_port           = "6443"
  protocol          = "tcp"
  security_group_id = aws_security_group.rke2-ec2.id
  cidr_blocks       = [for net in aws_subnet.rke2-private : net.cidr_block]
}

resource "aws_security_group_rule" "rke2-ec2-egress-world" {
  for_each          = var.nat_gateways ? { public = "true" } : {}
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  security_group_id = aws_security_group.rke2-ec2.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "rke2-ec2-egress-s3" {
  type              = "egress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  security_group_id = aws_security_group.rke2-ec2.id
  prefix_list_ids   = [aws_vpc_endpoint.rke2-s3.prefix_list_id]
}

resource "aws_security_group_rule" "rke2-ec2-egress-endpoints" {
  type                     = "egress"
  from_port                = "443"
  to_port                  = "443"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rke2-ec2.id
  source_security_group_id = aws_security_group.rke2-endpoints.id
}

resource "aws_security_group_rule" "rke2-ec2-egress-efs" {
  type                     = "egress"
  from_port                = "2049"
  to_port                  = "2049"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rke2-ec2.id
  source_security_group_id = aws_security_group.rke2-efs.id
}

# security group for endpoints
resource "aws_security_group" "rke2-endpoints" {
  name_prefix = "${local.prefix}-${local.suffix}-endpoints"
  description = "SG for ${local.prefix}-${local.suffix}-endpoints"
  vpc_id      = aws_vpc.rke2.id
  tags = {
    Name = "${local.prefix}-${local.suffix}-endpoints"
  }
}

resource "aws_security_group_rule" "rke2-endpoints-ingress-ec2-sg" {
  type                     = "ingress"
  from_port                = "443"
  to_port                  = "443"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rke2-endpoints.id
  source_security_group_id = aws_security_group.rke2-ec2.id
}

resource "aws_security_group_rule" "rke2-endpoints-ingress-ec2-net" {
  type              = "ingress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  security_group_id = aws_security_group.rke2-endpoints.id
  cidr_blocks       = [for net in aws_subnet.rke2-private : net.cidr_block]
}

# security group for efs
resource "aws_security_group" "rke2-efs" {
  name_prefix = "${local.prefix}-${local.suffix}-efs"
  description = "SG for ${local.prefix}-${local.suffix}-efs"
  vpc_id      = aws_vpc.rke2.id
  tags = {
    Name = "${local.prefix}-${local.suffix}-efs"
  }
}

resource "aws_security_group_rule" "rke2-efs-ingress-ec2-sg" {
  type                     = "ingress"
  from_port                = "2049"
  to_port                  = "2049"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rke2-efs.id
  source_security_group_id = aws_security_group.rke2-ec2.id
}
