data "aws_iam_policy_document" "rke2-s3-private" {

  statement {
    sid = "CreatorAdmin"
    actions = [
      "s3:*"
    ]
    resources = [aws_s3_bucket.rke2-private.arn]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.rke2.arn]
    }
  }

  statement {
    sid    = "InstanceGet"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      aws_s3_bucket.rke2-private.arn,
      "${aws_s3_bucket.rke2-private.arn}/data/*",
      "${aws_s3_bucket.rke2-private.arn}/scripts/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.rke2-ec2-controlplane.arn, aws_iam_role.rke2-ec2-nodes.arn]
    }
  }

  statement {
    sid    = "InstancePut"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${aws_s3_bucket.rke2-private.arn}/data/*",
      "${aws_s3_bucket.rke2-private.arn}/oidc/*",
      "${aws_s3_bucket.rke2-private.arn}/ssm/*",
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.rke2-ec2-controlplane.arn, aws_iam_role.rke2-ec2-nodes.arn]
    }
  }

  statement {
    sid    = "LambdaPutgetfiles"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
    ]
    resources = [
      aws_s3_bucket.rke2-private.arn,
      "${aws_s3_bucket.rke2-private.arn}/data/*",
      "${aws_s3_bucket.rke2-private.arn}/scripts/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.rke2-lambda-getfiles.arn]
    }
  }

  statement {
    sid    = "LambdaGetOidcProvider"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectAcl",
    ]
    resources = [
      aws_s3_bucket.rke2-private.arn,
      "${aws_s3_bucket.rke2-private.arn}/oidc/*",
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.rke2-lambda-oidcprovider.arn]
    }
  }

  statement {
    sid    = "CodebuildCodepipelineUse"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.rke2-private.arn,
      "${aws_s3_bucket.rke2-private.arn}/containers*",
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.rke2-codebuild.arn, aws_iam_role.rke2-codepipeline.arn]
    }
  }

}

data "aws_iam_policy_document" "rke2-s3-public" {

  statement {
    sid = "CreatorAdmin"
    actions = [
      "s3:*"
    ]
    resources = [aws_s3_bucket.rke2-public.arn]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.rke2.arn]
    }
  }

  statement {
    sid    = "LambdaPutOidcProvider"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
    ]
    resources = [
      aws_s3_bucket.rke2-public.arn,
      "${aws_s3_bucket.rke2-public.arn}/oidc/*",
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.rke2-lambda-oidcprovider.arn]
    }
  }

  statement {
    sid = "PublicRead"
    actions = [
      "s3:GetObject",
    ]
    resources = ["${aws_s3_bucket.rke2-public.arn}/oidc/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  statement {
    sid    = "PublicDeny"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    not_resources = ["${aws_s3_bucket.rke2-public.arn}/oidc/*"]
    not_principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.rke2.arn, aws_iam_role.rke2-lambda-oidcprovider.arn]
    }
  }

}
