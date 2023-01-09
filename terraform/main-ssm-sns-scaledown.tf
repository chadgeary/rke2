# sns topic called by lifecycle hooks
resource "aws_sns_topic" "rke2-scaledown" {
  name              = "${local.prefix}-${local.suffix}-scaledown"
  kms_master_key_id = aws_kms_key.rke2["sns"].arn
  delivery_policy   = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
}

# sns subscription for lambda
resource "aws_sns_topic_subscription" "rke2-scaledown" {
  topic_arn = aws_sns_topic.rke2-scaledown.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.rke2-scaledown.arn
}

# document to run at scaledown
resource "aws_ssm_document" "rke2-scaledown" {
  name          = "${local.prefix}-${local.suffix}-scaledown"
  document_type = "Command"
  content       = <<DOC
{
 "schemaVersion": "2.2",
 "description": "Autoscaling for rke2",
 "parameters": {
  "ASGNAME": {
   "type":"String",
   "description":"ASG Name"
  },
  "LIFECYCLEHOOKNAME": {
   "type":"String",
   "description":"LCH Name"
  }
 },
 "mainSteps": [
  {
   "action": "aws:runShellScript",
   "name": "runShellScript",
   "inputs": {
    "timeoutSeconds": "540",
    "runCommand": [
     "#!/bin/bash",
     "export LIFECYCLEHOOKNAME='{{ LIFECYCLEHOOKNAME }}'",
     "export ASGNAME='{{ ASGNAME }}'",
     "export RKE2_URL=https://control-plane.${local.prefix}-${local.suffix}.internal:6443",
     "/usr/local/bin/scaledown.sh"
    ]
   }
  }
 ]
}
DOC
}
