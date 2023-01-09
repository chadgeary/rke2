## autoscaling
resource "aws_iam_service_linked_role" "rke2" {
  aws_service_name = "autoscaling.amazonaws.com"
  custom_suffix    = "${local.prefix}-${local.suffix}"
}

resource "aws_iam_policy" "rke2-ec2-passrole" {
  name   = "${local.prefix}-${local.suffix}-ec2-passrole"
  path   = "/"
  policy = data.aws_iam_policy_document.rke2-ec2-passrole.json
}

resource "aws_iam_user_policy_attachment" "rke2-ec2-passrole" {
  user       = element(split("/", data.aws_caller_identity.rke2.arn), 1)
  policy_arn = aws_iam_policy.rke2-ec2-passrole.arn
}

## autoscaling lifecycle hook (sns -> ssm)
resource "aws_iam_role" "rke2-scaledown" {
  name               = "${local.prefix}-${local.suffix}-scaledown"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.rke2-scaledown-trust.json
}

resource "aws_iam_policy" "rke2-scaledown" {
  name   = "${local.prefix}-${local.suffix}-scaledown"
  path   = "/"
  policy = data.aws_iam_policy_document.rke2-scaledown.json
}

resource "aws_iam_role_policy_attachment" "rke2-scaledown" {
  role       = aws_iam_role.rke2-scaledown.name
  policy_arn = aws_iam_policy.rke2-scaledown.arn
}

## codebuild
resource "aws_iam_role" "rke2-codebuild" {
  name               = "${local.prefix}-${local.suffix}-codebuild"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.rke2-codebuild-trust.json
}

resource "aws_iam_policy" "rke2-codebuild" {
  name   = "${local.prefix}-${local.suffix}-codebuild"
  path   = "/"
  policy = data.aws_iam_policy_document.rke2-codebuild.json
}

resource "aws_iam_role_policy_attachment" "rke2-codebuild" {
  role       = aws_iam_role.rke2-codebuild.name
  policy_arn = aws_iam_policy.rke2-codebuild.arn
}

## codepipeline
resource "aws_iam_role" "rke2-codepipeline" {
  name               = "${local.prefix}-${local.suffix}-codepipeline"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.rke2-codepipeline-trust.json
}

resource "aws_iam_policy" "rke2-codepipeline" {
  name   = "${local.prefix}-${local.suffix}-codepipeline"
  path   = "/"
  policy = data.aws_iam_policy_document.rke2-codepipeline.json
}

resource "aws_iam_role_policy_attachment" "rke2-codepipeline" {
  role       = aws_iam_role.rke2-codepipeline.name
  policy_arn = aws_iam_policy.rke2-codepipeline.arn
}

## ec2 
resource "aws_iam_role" "rke2-ec2-controlplane" {
  name               = "${local.prefix}-${local.suffix}-ec2-controlplane"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.rke2-ec2-trust.json
}

resource "aws_iam_policy" "rke2-ec2-controlplane" {
  name   = "${local.prefix}-${local.suffix}-ec2-controlplane"
  path   = "/"
  policy = data.aws_iam_policy_document.rke2-ec2-controlplane.json
}

resource "aws_iam_role_policy_attachment" "rke2-ec2-controlplane" {
  role       = aws_iam_role.rke2-ec2-controlplane.name
  policy_arn = aws_iam_policy.rke2-ec2-controlplane.arn
}

resource "aws_iam_role_policy_attachment" "rke2-ec2-controlplane-managed" {
  role       = aws_iam_role.rke2-ec2-controlplane.name
  policy_arn = data.aws_iam_policy.rke2-ec2-managed.arn
}

resource "aws_iam_instance_profile" "rke2-ec2-controlplane" {
  name = "${local.prefix}-${local.suffix}-ec2-controlplane"
  role = aws_iam_role.rke2-ec2-controlplane.name
}

resource "aws_iam_role" "rke2-ec2-nodes" {
  name               = "${local.prefix}-${local.suffix}-ec2-nodes"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.rke2-ec2-trust.json
}

resource "aws_iam_policy" "rke2-ec2-nodes" {
  name   = "${local.prefix}-${local.suffix}-ec2-nodes"
  path   = "/"
  policy = data.aws_iam_policy_document.rke2-ec2-nodes.json
}

resource "aws_iam_role_policy_attachment" "rke2-ec2-nodes" {
  role       = aws_iam_role.rke2-ec2-nodes.name
  policy_arn = aws_iam_policy.rke2-ec2-nodes.arn
}

resource "aws_iam_role_policy_attachment" "rke2-ec2-nodes-managed" {
  role       = aws_iam_role.rke2-ec2-nodes.name
  policy_arn = data.aws_iam_policy.rke2-ec2-managed.arn
}

resource "aws_iam_instance_profile" "rke2-ec2-nodes" {
  name = "${local.prefix}-${local.suffix}-ec2-nodes"
  role = aws_iam_role.rke2-ec2-nodes.name
}

## lambda
resource "aws_iam_role" "rke2-lambda-getfiles" {
  name               = "${local.prefix}-${local.suffix}-lambda-getfiles"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.rke2-lambda-getfiles-trust.json
}

resource "aws_iam_policy" "rke2-lambda-getfiles" {
  name   = "${local.prefix}-${local.suffix}-lambda-getfiles"
  path   = "/"
  policy = data.aws_iam_policy_document.rke2-lambda-getfiles.json
}

resource "aws_iam_role_policy_attachment" "rke2-lambda-getfiles" {
  role       = aws_iam_role.rke2-lambda-getfiles.name
  policy_arn = aws_iam_policy.rke2-lambda-getfiles.arn
}

resource "aws_iam_role_policy_attachment" "rke2-lambda-getfiles-managed-1" {
  role       = aws_iam_role.rke2-lambda-getfiles.name
  policy_arn = data.aws_iam_policy.rke2-lambda-getfiles-managed-1.arn
}

resource "aws_iam_role_policy_attachment" "rke2-lambda-getfiles-managed-2" {
  role       = aws_iam_role.rke2-lambda-getfiles.name
  policy_arn = data.aws_iam_policy.rke2-lambda-getfiles-managed-2.arn
}

resource "aws_iam_role" "rke2-lambda-oidcprovider" {
  name               = "${local.prefix}-${local.suffix}-lambda-oidcprovider"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.rke2-lambda-oidcprovider-trust.json
}

resource "aws_iam_policy" "rke2-lambda-oidcprovider" {
  name   = "${local.prefix}-${local.suffix}-lambda-oidcprovider"
  path   = "/"
  policy = data.aws_iam_policy_document.rke2-lambda-oidcprovider.json
}

resource "aws_iam_role_policy_attachment" "rke2-lambda-oidcprovider" {
  role       = aws_iam_role.rke2-lambda-oidcprovider.name
  policy_arn = aws_iam_policy.rke2-lambda-oidcprovider.arn
}

resource "aws_iam_role_policy_attachment" "rke2-lambda-oidcprovider-managed-1" {
  role       = aws_iam_role.rke2-lambda-oidcprovider.name
  policy_arn = data.aws_iam_policy.rke2-lambda-oidcprovider-managed-1.arn
}

resource "aws_iam_role_policy_attachment" "rke2-lambda-oidcprovider-managed-2" {
  role       = aws_iam_role.rke2-lambda-oidcprovider.name
  policy_arn = data.aws_iam_policy.rke2-lambda-oidcprovider-managed-2.arn
}

resource "aws_iam_role" "rke2-lambda-scaledown" {
  name               = "${local.prefix}-${local.suffix}-lambda-scaledown"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.rke2-lambda-scaledown-trust.json
}

resource "aws_iam_policy" "rke2-lambda-scaledown" {
  name   = "${local.prefix}-${local.suffix}-lambda-scaledown"
  path   = "/"
  policy = data.aws_iam_policy_document.rke2-lambda-scaledown.json
}

resource "aws_iam_role_policy_attachment" "rke2-lambda-scaledown" {
  role       = aws_iam_role.rke2-lambda-scaledown.name
  policy_arn = aws_iam_policy.rke2-lambda-scaledown.arn
}

resource "aws_iam_role_policy_attachment" "rke2-lambda-scaledown-managed-1" {
  role       = aws_iam_role.rke2-lambda-scaledown.name
  policy_arn = data.aws_iam_policy.rke2-lambda-scaledown-managed-1.arn
}

resource "aws_iam_role_policy_attachment" "rke2-lambda-scaledown-managed-2" {
  role       = aws_iam_role.rke2-lambda-scaledown.name
  policy_arn = data.aws_iam_policy.rke2-lambda-scaledown-managed-2.arn
}

resource "aws_iam_role" "rke2-lambda-r53updater" {
  name               = "${local.prefix}-${local.suffix}-lambda-r53updater"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.rke2-lambda-r53updater-trust.json
}

resource "aws_iam_policy" "rke2-lambda-r53updater" {
  name   = "${local.prefix}-${local.suffix}-lambda-r53updater"
  path   = "/"
  policy = data.aws_iam_policy_document.rke2-lambda-r53updater.json
}

resource "aws_iam_role_policy_attachment" "rke2-lambda-r53updater" {
  role       = aws_iam_role.rke2-lambda-r53updater.name
  policy_arn = aws_iam_policy.rke2-lambda-r53updater.arn
}

resource "aws_iam_role_policy_attachment" "rke2-lambda-r53updater-managed-1" {
  role       = aws_iam_role.rke2-lambda-r53updater.name
  policy_arn = data.aws_iam_policy.rke2-lambda-r53updater-managed-1.arn
}

resource "aws_iam_role_policy_attachment" "rke2-lambda-r53updater-managed-2" {
  role       = aws_iam_role.rke2-lambda-r53updater.name
  policy_arn = data.aws_iam_policy.rke2-lambda-r53updater-managed-2.arn
}

## irsa
resource "aws_iam_role" "rke2-irsa" {
  name               = "${local.prefix}-${local.suffix}-irsa"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.rke2-irsa-trust.json
}

resource "aws_iam_policy" "rke2-irsa" {
  name   = "${local.prefix}-${local.suffix}-irsa"
  path   = "/"
  policy = data.aws_iam_policy_document.rke2-irsa.json
}

resource "aws_iam_role_policy_attachment" "rke2-irsa" {
  role       = aws_iam_role.rke2-irsa.name
  policy_arn = aws_iam_policy.rke2-irsa.arn
}

## aws-cloud-controller-manager
resource "aws_iam_role" "rke2-aws-cloud-controller-manager" {
  name               = "${local.prefix}-${local.suffix}-aws-cloud-controller-manager"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.rke2-aws-cloud-controller-manager-trust.json
}

resource "aws_iam_policy" "rke2-aws-cloud-controller-manager" {
  name   = "${local.prefix}-${local.suffix}-aws-cloud-controller-manager"
  path   = "/"
  policy = data.aws_iam_policy_document.rke2-aws-cloud-controller-manager.json
}

resource "aws_iam_role_policy_attachment" "rke2-aws-cloud-controller-manager" {
  role       = aws_iam_role.rke2-aws-cloud-controller-manager.name
  policy_arn = aws_iam_policy.rke2-aws-cloud-controller-manager.arn
}

## external-dns - only viable if using nat gateway(s)
resource "aws_iam_role" "rke2-external-dns" {
  for_each           = var.nat_gateways ? { external-dns = true } : {}
  name               = "${local.prefix}-${local.suffix}-external-dns"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.rke2-external-dns-trust["external-dns"].json
}

resource "aws_iam_policy" "rke2-external-dns" {
  for_each = var.nat_gateways ? { external-dns = true } : {}
  name     = "${local.prefix}-${local.suffix}-external-dns"
  path     = "/"
  policy   = data.aws_iam_policy_document.rke2-external-dns["external-dns"].json
}

resource "aws_iam_role_policy_attachment" "rke2-external-dns" {
  for_each   = var.nat_gateways ? { external-dns = true } : {}
  role       = aws_iam_role.rke2-external-dns["external-dns"].name
  policy_arn = aws_iam_policy.rke2-external-dns["external-dns"].arn
}
