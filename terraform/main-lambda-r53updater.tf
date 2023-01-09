data "archive_file" "rke2-r53updater" {
  type        = "zip"
  source_file = "main-lambda-r53updater.py"
  output_path = "main-lambda-r53updater.zip"
}

resource "aws_lambda_function" "rke2-r53updater" {
  filename         = "main-lambda-r53updater.zip"
  source_code_hash = data.archive_file.rke2-r53updater.output_base64sha256
  function_name    = "${local.prefix}-${local.suffix}-r53updater"
  role             = aws_iam_role.rke2-lambda-r53updater.arn
  kms_key_arn      = aws_kms_key.rke2["lambda"].arn
  memory_size      = 256
  handler          = "main-lambda-r53updater.lambda_handler"
  runtime          = "python3.9"
  timeout          = 45
  environment {
    variables = {
      PREFIX         = local.prefix
      SUFFIX         = local.suffix
      HOSTED_ZONE_ID = aws_route53_zone.rke2.id
      SSM_KEY_ID     = aws_kms_key.rke2["ssm"].key_id
    }
  }
  depends_on = [aws_cloudwatch_log_group.rke2-lambda-r53updater]
}

# allow cw to call lambda
resource "aws_lambda_permission" "rke2-r53updater" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rke2-r53updater.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rke2-r53updater.arn
}
