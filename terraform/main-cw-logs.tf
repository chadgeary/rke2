resource "aws_cloudwatch_log_group" "rke2-codebuild" {
  name              = "/aws/codebuild/${local.prefix}-${local.suffix}-codebuild"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = aws_kms_key.rke2["cw"].arn
  tags = {
    Name = "/aws/codebuild/${local.prefix}-${local.suffix}-codebuild"
  }
}

resource "aws_cloudwatch_log_group" "rke2-ec2" {
  name              = "/aws/ec2/${local.prefix}-${local.suffix}"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = aws_kms_key.rke2["cw"].arn
  tags = {
    Name = "/aws/ec2/${local.prefix}-${local.suffix}"
  }
}

resource "aws_cloudwatch_log_group" "rke2-lambda-getfiles" {
  name              = "/aws/lambda/${local.prefix}-${local.suffix}-getfiles"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = aws_kms_key.rke2["cw"].arn
  tags = {
    Name = "/aws/lambda/${local.prefix}-${local.suffix}-getfiles"
  }
}

resource "aws_cloudwatch_log_group" "rke2-lambda-oidcprovider" {
  name              = "/aws/lambda/${local.prefix}-${local.suffix}-oidcprovider"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = aws_kms_key.rke2["cw"].arn
  tags = {
    Name = "/aws/lambda/${local.prefix}-${local.suffix}-oidcprovider"
  }
}

resource "aws_cloudwatch_log_group" "rke2-lambda-scaledown" {
  name              = "/aws/lambda/${local.prefix}-${local.suffix}-scaledown"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = aws_kms_key.rke2["cw"].arn
  tags = {
    Name = "/aws/lambda/${local.prefix}-${local.suffix}-scaledown"
  }
}

resource "aws_cloudwatch_log_group" "rke2-lambda-r53updater" {
  name              = "/aws/lambda/${local.prefix}-${local.suffix}-r53updater"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = aws_kms_key.rke2["cw"].arn
  tags = {
    Name = "/aws/lambda/${local.prefix}-${local.suffix}-r53updater"
  }
}
