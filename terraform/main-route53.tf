resource "aws_route53_zone" "rke2" {
  name = "${local.prefix}-${local.suffix}.internal"
  vpc {
    vpc_id = aws_vpc.rke2.id
  }
  force_destroy = true
}
