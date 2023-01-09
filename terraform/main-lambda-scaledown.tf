data "archive_file" "rke2-scaledown" {
  type        = "zip"
  source_file = "main-lambda-scaledown.py"
  output_path = "main-lambda-scaledown.zip"
}

resource "aws_lambda_function" "rke2-scaledown" {
  filename         = "main-lambda-scaledown.zip"
  source_code_hash = data.archive_file.rke2-scaledown.output_base64sha256
  function_name    = "${local.prefix}-${local.suffix}-scaledown"
  role             = aws_iam_role.rke2-lambda-scaledown.arn
  kms_key_arn      = aws_kms_key.rke2["lambda"].arn
  memory_size      = 256
  handler          = "main-lambda-scaledown.lambda_handler"
  runtime          = "python3.9"
  timeout          = 300
  environment {
    variables = {
      SSMDOCUMENTNAME = aws_ssm_document.rke2-scaledown.name
    }
  }
  depends_on = [aws_cloudwatch_log_group.rke2-lambda-scaledown]
}

# allow sns to call lambda
resource "aws_lambda_permission" "rke2-scaledown" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rke2-scaledown.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.rke2-scaledown.arn
}
