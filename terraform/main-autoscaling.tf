# launch template per node group
resource "aws_launch_template" "rke2" {
  for_each               = var.nodegroups
  name_prefix            = "${local.prefix}-${local.suffix}-${each.key}"
  vpc_security_group_ids = [aws_security_group.rke2-ec2.id]
  iam_instance_profile {
    arn = each.key == "control-plane" ? aws_iam_instance_profile.rke2-ec2-controlplane.arn : aws_iam_instance_profile.rke2-ec2-nodes.arn
  }
  ebs_optimized = true
  image_id      = data.aws_ami.rke2[each.value.ami].id
  block_device_mappings {
    device_name = data.aws_ami.rke2[each.value.ami].root_device_name
    ebs {
      volume_size           = each.value.volume.gb
      volume_type           = each.value.volume.type
      encrypted             = true
      kms_key_id            = aws_kms_key.rke2["ec2"].arn
      delete_on_termination = true
    }
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = each.key == "control-plane" ? 3 : 1
  }
  private_dns_name_options {
    hostname_type = "resource-name"
  }
}

# the autoscaling group
resource "aws_autoscaling_group" "rke2" {
  for_each    = var.nodegroups
  name = "${local.prefix}-${local.suffix}-${each.key}"
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.rke2[each.key].id
        version            = "$Latest"
      }
      dynamic "override" {
        for_each = each.value.instance_types
        content {
          instance_type     = override.value
          weighted_capacity = "1"
        }
      }
    }
  }

  service_linked_role_arn   = aws_iam_service_linked_role.rke2.arn
  termination_policies      = ["ClosestToNextInstanceHour"]
  min_size                  = each.value.scaling_count.min
  max_size                  = each.value.scaling_count.max
  health_check_type         = "EC2"
  health_check_grace_period = "600"
  vpc_zone_identifier       = [for net in aws_subnet.rke2-private : net.id]

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = false
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${local.prefix}-${local.suffix}"
    value               = "owned"
    propagate_at_launch = false
  }

  tag {
    key                 = "kubernetes.io/cluster/${local.prefix}-${local.suffix}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${each.key}.${local.prefix}-${local.suffix}.internal"
    propagate_at_launch = true
  }

  tag {
    key                 = "cluster.k8s.amazonaws.com/name"
    value               = "${local.prefix}-${local.suffix}"
    propagate_at_launch = true
  }

  depends_on = [
    aws_iam_user_policy_attachment.rke2-ec2-passrole,
    aws_iam_role_policy_attachment.rke2-ec2-controlplane,
    aws_iam_role_policy_attachment.rke2-ec2-nodes,
    aws_iam_role_policy_attachment.rke2-ec2-controlplane-managed,
    aws_iam_role_policy_attachment.rke2-ec2-nodes-managed,
    aws_route53_zone.rke2,
    aws_s3_bucket_policy.rke2-private,
    aws_s3_bucket_policy.rke2-public,
    aws_s3_object.scripts,
    aws_s3_object.charts,
    aws_ssm_association.rke2,
    aws_vpc_endpoint_subnet_association.rke2-vpces,
  ]
}

resource "aws_autoscaling_lifecycle_hook" "rke2" {
  for_each                = var.nodegroups
  name                    = "${local.prefix}-${local.suffix}-${each.key}"
  autoscaling_group_name  = aws_autoscaling_group.rke2[each.key].name
  default_result          = "ABANDON"
  heartbeat_timeout       = 600
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  notification_target_arn = aws_sns_topic.rke2-scaledown.arn
  role_arn                = aws_iam_role.rke2-scaledown.arn
}
