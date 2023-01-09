data "aws_iam_policy_document" "rke2-codebuild-trust" {
  statement {
    sid = "ForCodebuildPipelineOnly"
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com", "codepipeline.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "rke2-codebuild" {

  statement {
    sid = "UseS3"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject"
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.rke2-private.arn,
      "${aws_s3_bucket.rke2-private.arn}/containers*"
    ]
  }

  statement {
    sid = "UseKMS"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    effect    = "Allow"
    resources = [aws_kms_key.rke2["codebuild"].arn, aws_kms_key.rke2["s3"].arn]
  }

  statement {
    sid = "UseCloudwatch"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect = "Allow"
    resources = [
      aws_cloudwatch_log_group.rke2-codebuild.arn,
      "arn:${data.aws_partition.rke2.partition}:logs:${var.region}:${data.aws_caller_identity.rke2.account_id}:log-group:/aws/codebuild/${local.prefix}-${local.suffix}-codebuild*"
    ]
  }

  statement {
    sid = "UseECR"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeImageScanFindings",
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

}
