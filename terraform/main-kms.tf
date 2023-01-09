resource "aws_kms_key" "rke2" {
  for_each                 = toset(["codebuild", "cw", "ec2", "ecr", "efs", "lambda", "s3", "sns", "ssm"])
  description              = "${local.prefix}-${local.suffix}-${each.value}"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = "true"
  deletion_window_in_days  = 7
  tags = {
    Name = "${local.prefix}-${local.suffix}-${each.value}"
  }
  policy = data.aws_iam_policy_document.rke2-kms[each.value].json
}
