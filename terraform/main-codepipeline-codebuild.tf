resource "aws_codebuild_project" "rke2" {
  for_each       = toset(["arm64", "x86_64", "multiarch"])
  name           = "${local.prefix}-${local.suffix}-codebuild-${each.key}"
  description    = "${local.prefix}-${local.suffix}"
  service_role   = aws_iam_role.rke2-codebuild.arn
  encryption_key = aws_kms_key.rke2["codebuild"].arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = each.key == "arm64" ? "aws/codebuild/amazonlinux2-aarch64-standard:2.0" : "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type            = each.key == "arm64" ? "ARM_CONTAINER" : "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable {
      name  = "BUILD_ARCH"
      value = each.key
    }
  }

  dynamic "source" {
    for_each = each.key == "multiarch" ? [1] : []
    content {
      type      = "CODEPIPELINE"
      buildspec = "multiarch.yml"
    }
  }

  dynamic "source" {
    for_each = each.key != "multiarch" ? [1] : []
    content {
      type = "CODEPIPELINE"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/aws/codebuild/${local.prefix}-${local.suffix}-codebuild"
    }
    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.rke2-private.id}/containers/build-log"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.rke2-codebuild, aws_cloudwatch_log_group.rke2-codebuild, aws_s3_object.containers]
}

# codepipeline can start faster than IAM propagates
resource "time_sleep" "codepipeline_iam" {
  depends_on      = [aws_iam_role_policy_attachment.rke2-codepipeline]
  create_duration = "15s"
}

resource "aws_codepipeline" "rke2" {
  for_each = aws_s3_object.containers
  name     = "containers-${local.prefix}-${local.suffix}-${replace(element(split(":", each.key), 0), "/", "-")}"
  role_arn = aws_iam_role.rke2-codepipeline.arn
  artifact_store {
    location = aws_s3_bucket.rke2-private.bucket
    type     = "S3"
    encryption_key {
      id   = aws_kms_key.rke2["s3"].arn
      type = "KMS"
    }
  }
  stage {
    name = "Source"
    action {
      name             = "s3"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      output_artifacts = ["source_output"]
      version          = "1"
      configuration = {
        S3Bucket             = aws_s3_bucket.rke2-private.bucket
        S3ObjectKey          = "containers/${replace(element(split(":", each.key), 0), "/", "-")}.zip"
        PollForSourceChanges = "false"
      }
    }
  }
  stage {
    name = "Builds"
    action {
      name            = "arm64"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"
      configuration = {
        ProjectName = aws_codebuild_project.rke2["arm64"].name
      }
    }
    action {
      name            = "x86_64"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"
      configuration = {
        ProjectName = aws_codebuild_project.rke2["x86_64"].name
      }
    }
  }
  stage {
    name = "Multiarch"
    action {
      name            = "multiarch"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"
      configuration = {
        ProjectName = aws_codebuild_project.rke2["multiarch"].name
      }
    }
  }
  depends_on = [aws_ecr_repository.rke2, aws_iam_role_policy_attachment.rke2-codepipeline, time_sleep.codepipeline_iam]
}
