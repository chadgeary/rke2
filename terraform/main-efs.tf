resource "aws_efs_file_system" "rke2" {
  creation_token   = "${local.prefix}-${local.suffix}"
  encrypted        = "true"
  kms_key_id       = aws_kms_key.rke2["efs"].arn
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

resource "aws_efs_file_system_policy" "rke2" {
  file_system_id                     = aws_efs_file_system.rke2.id
  bypass_policy_lockout_safety_check = "false"
  policy                             = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "efs",
    "Statement": [
        {
            "Sid": "Mount",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Resource": "${aws_efs_file_system.rke2.arn}",
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "true"
                }
            }
        },
        {
            "Sid": "Caller",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${data.aws_caller_identity.rke2.arn}"
            },
            "Resource": "${aws_efs_file_system.rke2.arn}",
            "Action": [
                "elasticfilesystem:*"
            ]
        },
        {
            "Sid": "DriverControlPlane",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_iam_role.rke2-ec2-controlplane.arn}"
            },
            "Resource": "${aws_efs_file_system.rke2.arn}",
            "Action": [
                "elasticfilesystem:CreateAccessPoint",
                "elasticfilesystem:DeleteAccessPoint"
            ]
        }
    ]
}
POLICY
}

resource "aws_efs_mount_target" "rke2" {
  for_each        = local.private_nets
  file_system_id  = aws_efs_file_system.rke2.id
  subnet_id       = aws_subnet.rke2-private[each.key].id
  security_groups = [aws_security_group.rke2-efs.id]
}
