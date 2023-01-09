# vpc
resource "aws_vpc" "rke2" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "${local.prefix}-${local.suffix}"
  }
}

# route53 
resource "aws_vpc_dhcp_options" "rke2" {
  domain_name_servers = ["AmazonProvidedDNS"]
}

resource "aws_vpc_dhcp_options_association" "rke2" {
  vpc_id          = aws_vpc.rke2.id
  dhcp_options_id = aws_vpc_dhcp_options.rke2.id
}

## Private Network
# private route table(s) per zone
resource "aws_route_table" "rke2-private" {
  for_each = local.private_nets
  vpc_id   = aws_vpc.rke2.id
  dynamic "route" {
    for_each = var.nat_gateways ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.rke2[each.key].id
    }
  }
  tags = {
    Name                                                    = "${local.prefix}-${local.suffix}-${each.value.zone}"
    "kubernetes.io/cluster/${local.prefix}-${local.suffix}" = "shared"
  }
}

# private subnets
resource "aws_subnet" "rke2-private" {
  for_each          = local.private_nets
  vpc_id            = aws_vpc.rke2.id
  availability_zone = each.value.zone
  cidr_block        = each.value.cidr
  tags = {
    Name                                                    = "${local.prefix}-${local.suffix}-${each.value.zone}-private"
    "kubernetes.io/cluster/${local.prefix}-${local.suffix}" = "shared"
    "kubernetes.io/role/internal-elb"                       = "1"
  }
}

# private route table associations
resource "aws_route_table_association" "rke2-private" {
  for_each       = local.private_nets
  subnet_id      = aws_subnet.rke2-private[each.key].id
  route_table_id = aws_route_table.rke2-private[each.key].id
}

# s3 endpoint for private instance(s)
resource "aws_vpc_endpoint" "rke2-s3" {
  vpc_id            = aws_vpc.rke2.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [for aws_route_table in aws_route_table.rke2-private : aws_route_table.id]
  tags = {
    Name = "${local.prefix}-${local.suffix}-s3"
  }
}

# ssm endpoints for private instance(s)
resource "aws_vpc_endpoint" "rke2-vpces" {
  for_each            = var.vpc_endpoints ? local.vpces : toset([])
  vpc_id              = aws_vpc.rke2.id
  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.rke2-endpoints.id]
  private_dns_enabled = true
  tags = {
    Name = "${local.prefix}-${local.suffix}-${each.key}"
  }
}

resource "aws_vpc_endpoint_subnet_association" "rke2-vpces" {
  for_each        = var.vpc_endpoints ? local.subnet-vpce : {}
  subnet_id       = each.value.subnet
  vpc_endpoint_id = each.value.vpce
}

## Public Network
# igw for nat / external lbs
resource "aws_internet_gateway" "rke2" {
  for_each = var.nat_gateways ? { public = "true" } : {}
  vpc_id   = aws_vpc.rke2.id
  tags = {
    Name = "${local.prefix}-${local.suffix}"
  }
}

# public net(s) per zone
resource "aws_subnet" "rke2-public" {
  for_each          = var.nat_gateways ? local.public_nets : {}
  vpc_id            = aws_vpc.rke2.id
  availability_zone = each.value.zone
  cidr_block        = each.value.cidr
  tags = {
    Name                                                    = "${local.prefix}-${local.suffix}-${each.value.zone}-public"
    "kubernetes.io/cluster/${local.prefix}-${local.suffix}" = "shared"
    "kubernetes.io/role/elb"                                = "1"
  }
}

# public route via internet gateway
resource "aws_route_table" "rke2-public" {
  for_each = var.nat_gateways ? { public = "true" } : {}
  vpc_id   = aws_vpc.rke2.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rke2["public"].id
  }
  tags = {
    Name = "${local.prefix}-${local.suffix}"
  }
}

resource "aws_route_table_association" "rke2-public" {
  for_each       = var.nat_gateways ? local.public_nets : {}
  subnet_id      = aws_subnet.rke2-public[each.key].id
  route_table_id = aws_route_table.rke2-public["public"].id
}

# if var.nat_gateways = true
resource "aws_eip" "rke2" {
  for_each = var.nat_gateways ? local.public_nets : {}
  vpc      = true
  tags = {
    Name = "${local.prefix}-${local.suffix}-${each.value.zone}"
  }
}

resource "aws_nat_gateway" "rke2" {
  for_each      = var.nat_gateways ? local.public_nets : {}
  allocation_id = aws_eip.rke2[each.key].id
  subnet_id     = aws_subnet.rke2-public[each.key].id
  tags = {
    Name = "${local.prefix}-${local.suffix}-${each.value.zone}"
  }
}
