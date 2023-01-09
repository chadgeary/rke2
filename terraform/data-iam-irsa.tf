data "aws_iam_policy_document" "rke2-irsa-trust" {
  statement {
    sid = "ForIrsa"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["arn:${data.aws_partition.rke2.partition}:iam::${data.aws_caller_identity.rke2.account_id}:oidc-provider/s3.${var.region}.amazonaws.com/${local.prefix}-${local.suffix}-public/oidc"]
    }
    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "s3.${var.region}.amazonaws.com/${local.prefix}-${local.suffix}-public/oidc:sub"
      values   = ["system:serviceaccount:${local.prefix}-${local.suffix}:irsa"] # system:serviceaccount:namespace:serviceaccountname
    }
  }
}

data "aws_iam_policy_document" "rke2-irsa" {

  statement {
    sid = "ListBucket"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.rke2-private.arn,
      "${aws_s3_bucket.rke2-private.arn}/irsa/*",
    ]
  }

  statement {
    sid = "UseKMSS3"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    effect    = "Allow"
    resources = [aws_kms_key.rke2["s3"].arn]
  }

}
