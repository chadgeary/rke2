data "archive_file" "rke2-oidcprovider" {
  type        = "zip"
  source_file = "main-lambda-oidcprovider.py"
  output_path = "main-lambda-oidcprovider.zip"
}

resource "aws_lambda_function" "rke2-oidcprovider" {
  filename         = "main-lambda-oidcprovider.zip"
  source_code_hash = data.archive_file.rke2-oidcprovider.output_base64sha256
  function_name    = "${local.prefix}-${local.suffix}-oidcprovider"
  role             = aws_iam_role.rke2-lambda-oidcprovider.arn
  kms_key_arn      = aws_kms_key.rke2["lambda"].arn
  memory_size      = 256
  handler          = "main-lambda-oidcprovider.lambda_handler"
  runtime          = "python3.9"
  timeout          = 900
  environment {
    variables = {
      ACCOUNT        = data.aws_caller_identity.rke2.account_id
      BUCKET_PUBLIC  = aws_s3_bucket.rke2-public.id
      BUCKET_PRIVATE = aws_s3_bucket.rke2-private.id
      OBJECT_TIMEOUT = 800
      REGION         = var.region
      PREFIX         = local.prefix
      SUFFIX         = local.suffix
    }
  }
  depends_on = [aws_cloudwatch_log_group.rke2-lambda-oidcprovider, aws_autoscaling_group.rke2["control-plane"]]
}

# data "aws_lambda_invocation" "rke2-oidcprovider" {
#   count         = var.nodegroups["control-plane"].scaling_count.min > 0 ? 1 : 0
#   function_name = aws_lambda_function.rke2-oidcprovider.function_name
#   input         = <<JSON
# {
#  "caller":"terraform"
# }
# JSON
#   depends_on = [
#     aws_iam_role_policy_attachment.rke2-lambda-oidcprovider,
#     aws_iam_role_policy_attachment.rke2-lambda-oidcprovider-managed-1,
#     aws_iam_role_policy_attachment.rke2-lambda-oidcprovider-managed-2,
#     aws_autoscaling_group.rke2,
#     aws_ssm_association.rke2
#   ]
# }
