resource "random_string" "suffix" {
  length  = 2
  upper   = false
  special = false
}

resource "local_file" "rke2" {
  filename        = "./connect.sh"
  file_permission = "0700"
  content = templatefile(
    "../templates/connect.sh.tftpl",
    {
      PROFILE = var.profile
      REGION  = var.region
      PREFIX  = local.prefix
      SUFFIX  = local.suffix
    }
  )
}

resource "local_file" "irsa" {
  filename        = "./manifests/irsa.yaml"
  file_permission = "0600"
  content = templatefile(
    "../templates/irsa.yaml.tftpl",
    {
      ACCOUNT  = data.aws_caller_identity.rke2.account_id
      REGION   = var.region
      ROLE_ARN = aws_iam_role.rke2-irsa.arn
      PREFIX   = local.prefix
      SUFFIX   = local.suffix
    }
  )
}
