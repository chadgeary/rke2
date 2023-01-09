data "archive_file" "rke2-getfiles" {
  type        = "zip"
  source_file = "main-lambda-getfiles.py"
  output_path = "main-lambda-getfiles.zip"
}

resource "aws_lambda_function" "rke2-getfiles" {
  filename         = "main-lambda-getfiles.zip"
  source_code_hash = data.archive_file.rke2-getfiles.output_base64sha256
  function_name    = "${local.prefix}-${local.suffix}-getfiles"
  role             = aws_iam_role.rke2-lambda-getfiles.arn
  kms_key_arn      = aws_kms_key.rke2["lambda"].arn
  memory_size      = 256
  handler          = "main-lambda-getfiles.lambda_handler"
  runtime          = "python3.9"
  timeout          = 900
  environment {
    variables = {
      BUCKET = aws_s3_bucket.rke2-private.id
      REGION = var.region
      KEY    = aws_kms_key.rke2["s3"].arn
    }
  }
  depends_on = [aws_cloudwatch_log_group.rke2-lambda-getfiles]
}

# invoke per var.lambda_to_s3
data "aws_lambda_invocation" "rke2-getfiles" {
  for_each      = var.lambda_to_s3
  function_name = aws_lambda_function.rke2-getfiles.function_name
  input         = <<JSON
{
 "url": "${each.value.url}",
 "prefix": "${each.value.prefix}"
}
JSON
  depends_on = [
    aws_iam_role_policy_attachment.rke2-lambda-getfiles,
    aws_iam_role_policy_attachment.rke2-lambda-getfiles-managed-1,
    aws_iam_role_policy_attachment.rke2-lambda-getfiles-managed-2
  ]
}
