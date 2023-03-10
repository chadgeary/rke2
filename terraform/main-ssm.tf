# Secrets
resource "aws_ssm_parameter" "rke2" {
  for_each = var.secrets
  name     = "/${local.prefix}-${local.suffix}/${each.key}"
  type     = "SecureString"
  key_id   = aws_kms_key.rke2["ssm"].key_id
  value    = each.value
}

# First Instance
resource "aws_ssm_parameter" "rke2-first-instance" {
  name   = "/${local.prefix}-${local.suffix}/FIRST_INSTANCE_ID"
  type   = "SecureString"
  key_id = aws_kms_key.rke2["ssm"].key_id
  value  = "unset"

  lifecycle {
    ignore_changes = [value]
  }
}

# Document
resource "aws_ssm_document" "rke2" {
  name          = "${local.prefix}-${local.suffix}"
  document_type = "Command"
  content       = <<DOC
  {
    "schemaVersion": "2.2",
    "description": "Shell Script via SSM",
    "parameters": {
    "SourceType": {
      "description": "(Optional) Specify the source type.",
      "type": "String",
      "allowedValues": [
      "GitHub",
      "S3"
      ]
    },
    "SourceInfo": {
      "description": "Specify 'path'. Important: If you specify S3, then the IAM instance profile on your managed instances must be configured with read access to Amazon S3.",
      "type": "StringMap",
      "displayType": "textarea",
      "default": {}
    },
    "ShellScriptFile": {
      "type": "String",
      "description": "(Optional) The shell script to run (including relative path). If the main file is located in the ./automation directory, then specify automation/script.sh.",
      "default": "hello-world.sh",
      "allowedPattern": "[(a-z_A-Z0-9\\-)/]+(.sh|.yaml)$"
    },
    "EnvVars": {
      "type": "String",
      "description": "(Optional) Additional variables to pass at runtime. Enter key/value pairs separated by a space. For example: color=red flavor=cherry",
      "default": "",
      "displayType": "textarea"
    }
    },
    "mainSteps": [
    {
      "action": "aws:downloadContent",
      "name": "downloadContent",
      "inputs": {
      "SourceType": "{{ SourceType }}",
      "SourceInfo": "{{ SourceInfo }}"
      }
    },
    {
      "action": "aws:runShellScript",
      "maxAttempts": 10,
      "name": "runShellScript",
      "inputs": {
      "runCommand": [
        "#!/bin/bash",
        "ShellScriptFile=\"{{ShellScriptFile}}\"",
        "export {{EnvVars}}",
        "if [ ! -f  \"$${ShellScriptFile}\" ] ; then",
        "   echo \"The specified ShellScript file doesn't exist in the downloaded bundle. Please review the relative path and file name.\" >&2",
        "   exit 2",
        "fi",
        "chmod +x \"$${ShellScriptFile}\" && /bin/bash ./\"$${ShellScriptFile}\""
      ]
      }
    }
    ]
  }
DOC
}

## association (bootstrap.sh)
resource "aws_ssm_association" "rke2" {
  for_each         = var.nodegroups
  association_name = "${local.prefix}-${local.suffix}-${each.key}"
  name             = aws_ssm_document.rke2.name
  targets {
    key    = "tag:Name"
    values = ["${each.key}.${local.prefix}-${local.suffix}.internal"]
  }
  output_location {
    s3_bucket_name = aws_s3_bucket.rke2-private.id
    s3_key_prefix  = "ssm/${each.key}"
  }
  parameters = {
    EnvVars         = "AWS_ADDON_URI=${local.aws_addon_uris[var.region]} ACCOUNT=${data.aws_caller_identity.rke2.account_id} AMI_TYPE=${each.value.ami} REGION=${var.region} PREFIX=${local.prefix} SUFFIX=${local.suffix} NODEGROUP=${each.key} POD_CIDR=${local.pod_cidr} SVC_CIDR=${local.svc_cidr} VPC_CIDR=${var.vpc_cidr} KUBEDNS_IP=${local.kubedns_ip} NAT_GATEWAYS=${tostring(var.nat_gateways)} EFS_ID=${aws_efs_file_system.rke2.id}"
    ShellScriptFile = "bootstrap.sh"
    SourceInfo      = "{\"path\":\"https://s3.${var.region}.amazonaws.com/${aws_s3_bucket.rke2-private.id}/scripts/\"}"
    SourceType      = "S3"
  }
  depends_on = [aws_lambda_function.rke2-getfiles, data.aws_lambda_invocation.rke2-getfiles]
}
