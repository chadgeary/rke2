resource "aws_cloudwatch_event_rule" "rke2-r53updater" {
  name                = "${local.prefix}-${local.suffix}-r53updater"
  schedule_expression = "rate(1 minute)"
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "rke2-r53updater" {
  arn  = aws_lambda_function.rke2-r53updater.arn
  rule = aws_cloudwatch_event_rule.rke2-r53updater.id
  depends_on = [
    aws_iam_role_policy_attachment.rke2-lambda-r53updater,
    aws_iam_role_policy_attachment.rke2-lambda-r53updater-managed-1,
    aws_iam_role_policy_attachment.rke2-lambda-r53updater-managed-2
  ]
}
