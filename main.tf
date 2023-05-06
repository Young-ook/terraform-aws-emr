### aws partitions
module "aws" {
  source = "Young-ook/spinnaker/aws//modules/aws-partitions"
}

locals {
  scaling         = local.cluster_enabled ? lookup(var.cluster, "scaling", local.default_cluster.scaling) : local.default_cluster.scaling
  master_fleet    = local.cluster_enabled ? lookup(var.cluster, "master_fleet", local.default_cluster.master_fleet) : local.default_cluster.master_fleet
  core_fleet      = local.cluster_enabled ? lookup(var.cluster, "core_fleet", local.default_cluster.core_fleet) : local.default_cluster.core_fleet
  task_fleet      = local.cluster_enabled ? lookup(var.cluster, "task_fleet", local.default_cluster.task_fleet) : local.default_cluster.task_fleet
  cluster_enabled = var.cluster != null
  studio_enabled  = var.studio != null
}

### security/policy
resource "aws_iam_role" "cp" {
  for_each = toset(local.cluster_enabled ? ["enabled"] : [])
  name     = join("-", [local.name, "cp"])
  tags     = merge(local.default-tags, var.tags)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = format("elasticmapreduce.%s", module.aws.partition.dns_suffix)
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "emr" {
  for_each   = toset(local.cluster_enabled ? ["enabled"] : [])
  role       = aws_iam_role.cp["enabled"].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

resource "aws_iam_role" "ng" {
  for_each = toset(local.cluster_enabled ? ["enabled"] : [])
  name     = join("-", [local.name, "ng"])
  tags     = merge(local.default-tags, var.tags)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = format("ec2.%s", module.aws.partition.dns_suffix)
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2" {
  for_each   = toset(local.cluster_enabled ? ["enabled"] : [])
  role       = aws_iam_role.ng["enabled"].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

resource "aws_iam_instance_profile" "ng" {
  for_each = toset(local.cluster_enabled ? ["enabled"] : [])
  name     = join("-", [local.name, "ng"])
  role     = aws_iam_role.ng["enabled"].name
}

### cluster/control
data "template_file" "scale-policy" {
  template = file("${path.module}/templates/scale-policy.tpl")
}

resource "aws_emr_cluster" "cp" {
  for_each                          = toset(local.cluster_enabled ? ["enabled"] : [])
  name                              = local.name
  tags                              = merge(local.default-tags, var.tags)
  service_role                      = aws_iam_role.cp["enabled"].arn
  release_label                     = lookup(var.cluster, "release", local.default_cluster.release)
  applications                      = concat(lookup(var.cluster, "applications", local.default_cluster.applications))
  termination_protection            = lookup(var.cluster, "termination_protections", local.default_cluster.termination_protection)
  keep_job_flow_alive_when_no_steps = true

  ec2_attributes {
    subnet_ids                        = var.subnets
    additional_master_security_groups = var.additional_master_security_group
    additional_slave_security_groups  = var.additional_slave_security_group
    instance_profile                  = aws_iam_instance_profile.ng["enabled"].arn
    key_name                          = lookup(var.cluster, "ssh_key", local.default_cluster.ssh_key)
  }

  dynamic "bootstrap_action" {
    for_each = { for k, v in lookup(var.cluster, "bootstrap", local.default_cluster.bootstrap) : k => v if length(lookup(var.cluster, "bootstrap", local.default_cluster.bootstrap)) > 0 }
    content {
      path = "s3://emr-bootstrap/actions/run-if"
      name = "runif"
      args = ["instance.isMaster=true", "echo running on master node"]
    }
  }

  master_instance_fleet {
    name                      = join("-", [local.name, "master-fleet"])
    target_on_demand_capacity = lookup(var.master_node_groups, "target_on_demand_capacity", local.default_master_node_groups.target_on_demand_capacity)

    dynamic "instance_type_configs" {
      for_each = { for k, v in lookup(var.master_node_groups, "instance_type_configs", local.default_instance_type_configs) : k => v }
      content {
        bid_price                                  = lookup(instance_type_configs.value, "bid_price", local.default_instance_type_config.bid_price)
        bid_price_as_percentage_of_on_demand_price = lookup(instance_type_configs.value, "bid_price_as_percentage_of_on_demand_price", local.default_instance_type_config.bid_price_as_percentage_of_on_demand_price)
        instance_type                              = lookup(instance_type_configs.value, "instance_type", local.default_instance_type_config.instance_type)
        weighted_capacity                          = lookup(instance_type_configs.value, "weighted_capacity", local.default_instance_type_config.weighted_capacity)

        dynamic "ebs_config" {
          for_each = { for k, v in instance_type_configs.value : k => v if k == "ebs_config" }
          content {
            size                 = lookup(ebs_config.value, "size", local.default_instance_type_config.ebs_config.size)
            type                 = lookup(ebs_config.value, "type", local.default_instance_type_config.ebs_config.type)
            volumes_per_instance = lookup(ebs_config.value, "volumes_per_instance", local.default_instance_type_config.ebs_config.volumes_per_instance)
          }
        }
      }
    }

    dynamic "launch_specifications" {
      for_each = [lookup(var.master_node_groups, "launch_specifications", local.default_master_node_groups.launch_specifications)]
      content {
        dynamic "on_demand_specification" {
          for_each = lookup(launch_specifications.value, "on_demand_specification", null) == null ? [] : [lookup(launch_specifications.value, "on_demand_specification")]
          content {
            allocation_strategy = lookup(on_demand_specification.value, "allocation_strategy", local.default_on_demand_specification.allocation_strategy)
          }
        }
        dynamic "spot_specification" {
          for_each = lookup(launch_specifications.value, "spot_specification", null) == null ? [] : [lookup(launch_specifications.value, "spot_specification")]
          content {
            allocation_strategy      = lookup(spot_specification.value, "allocation_strategy", local.default_spot_specification.allocation_strategy)
            block_duration_minutes   = lookup(spot_specification.value, "block_duration_minutes", local.default_spot_specification.block_duration_minutes)
            timeout_action           = lookup(spot_specification.value, "timeout_action", local.default_spot_specification.timeout_action)
            timeout_duration_minutes = lookup(spot_specification.value, "timeout_duration_minutes", local.default_spot_specification.timeout_duration_minutes)
          }
        }
      }
    }
  }

  core_instance_fleet {
    name                      = join("-", [local.name, "core-fleet"])
    target_on_demand_capacity = lookup(var.core_node_groups, "target_on_demand_capacity", local.default_core_node_groups.target_on_demand_capacity)
    target_spot_capacity      = lookup(var.core_node_groups, "target_spot_capacity", local.default_core_node_groups.target_spot_capacity)

    dynamic "instance_type_configs" {
      for_each = { for k, v in lookup(var.core_node_groups, "instance_type_configs", local.default_instance_type_configs) : k => v }
      content {
        bid_price                                  = lookup(instance_type_configs.value, "bid_price", local.default_instance_type_config.bid_price)
        bid_price_as_percentage_of_on_demand_price = lookup(instance_type_configs.value, "bid_price_as_percentage_of_on_demand_price", local.default_instance_type_config.bid_price_as_percentage_of_on_demand_price)
        instance_type                              = lookup(instance_type_configs.value, "instance_type", local.default_instance_type_config.instance_type)
        weighted_capacity                          = lookup(instance_type_configs.value, "weighted_capacity", local.default_instance_type_config.weighted_capacity)

        dynamic "ebs_config" {
          for_each = { for k, v in instance_type_configs.value : k => v if k == "ebs_config" }
          content {
            size                 = lookup(ebs_config.value, "size", local.default_instance_type_config.ebs_config.size)
            type                 = lookup(ebs_config.value, "type", local.default_instance_type_config.ebs_config.type)
            volumes_per_instance = lookup(ebs_config.value, "volumes_per_instance", local.default_instance_type_config.ebs_config.volumes_per_instance)
          }
        }
      }
    }

    dynamic "launch_specifications" {
      for_each = [lookup(var.core_node_groups, "launch_specifications", local.default_core_node_groups.launch_specifications)]
      content {
        dynamic "on_demand_specification" {
          for_each = lookup(launch_specifications.value, "on_demand_specification", null) == null ? [] : [lookup(launch_specifications.value, "on_demand_specification")]
          content {
            allocation_strategy = lookup(on_demand_specification.value, "allocation_strategy", local.default_on_demand_specification.allocation_strategy)
          }
        }
        dynamic "spot_specification" {
          for_each = lookup(launch_specifications.value, "spot_specification", null) == null ? [] : [lookup(launch_specifications.value, "spot_specification")]
          content {
            allocation_strategy      = lookup(spot_specification.value, "allocation_strategy", local.default_spot_specification.allocation_strategy)
            block_duration_minutes   = lookup(spot_specification.value, "block_duration_minutes", local.default_spot_specification.block_duration_minutes)
            timeout_action           = lookup(spot_specification.value, "timeout_action", local.default_spot_specification.timeout_action)
            timeout_duration_minutes = lookup(spot_specification.value, "timeout_duration_minutes", local.default_spot_specification.timeout_duration_minutes)
          }
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

### cluster/task
resource "aws_emr_instance_fleet" "dp" {
  for_each                  = toset(local.cluster_enabled ? ["enabled"] : [])
  cluster_id                = aws_emr_cluster.cp["enabled"].id
  name                      = join("-", [local.name, "task-fleet"])
  target_on_demand_capacity = lookup(var.task_node_groups, "target_on_demand_capacity", local.default_task_node_groups.target_on_demand_capacity)
  target_spot_capacity      = lookup(var.task_node_groups, "target_spot_capacity", local.default_task_node_groups.target_spot_capacity)

  dynamic "instance_type_configs" {
    for_each = { for k, v in lookup(var.task_node_groups, "instance_type_configs", local.default_instance_type_configs) : k => v }
    content {
      bid_price                                  = lookup(instance_type_configs.value, "bid_price", local.default_instance_type_config.bid_price)
      bid_price_as_percentage_of_on_demand_price = lookup(instance_type_configs.value, "bid_price_as_percentage_of_on_demand_price", local.default_instance_type_config.bid_price_as_percentage_of_on_demand_price)
      instance_type                              = lookup(instance_type_configs.value, "instance_type", local.default_instance_type_config.instance_type)
      weighted_capacity                          = lookup(instance_type_configs.value, "weighted_capacity", local.default_instance_type_config.weighted_capacity)

      dynamic "ebs_config" {
        for_each = { for k, v in instance_type_configs.value : k => v if k == "ebs_config" }
        content {
          size                 = lookup(ebs_config.value, "size", local.default_instance_type_config.ebs_config.size)
          type                 = lookup(ebs_config.value, "type", local.default_instance_type_config.ebs_config.type)
          volumes_per_instance = lookup(ebs_config.value, "volumes_per_instance", local.default_instance_type_config.ebs_config.volumes_per_instance)
        }
      }
    }
  }

  dynamic "launch_specifications" {
    for_each = [lookup(var.task_node_groups, "launch_specifications", local.default_task_node_groups.launch_specifications)]
    content {
      dynamic "on_demand_specification" {
        for_each = lookup(launch_specifications.value, "on_demand_specification", null) == null ? [] : [lookup(launch_specifications.value, "on_demand_specification")]
        content {
          allocation_strategy = lookup(on_demand_specification.value, "allocation_strategy", local.default_on_demand_specification.allocation_strategy)
        }
      }
      dynamic "spot_specification" {
        for_each = lookup(launch_specifications.value, "spot_specification", null) == null ? [] : [lookup(launch_specifications.value, "spot_specification")]
        content {
          allocation_strategy      = lookup(spot_specification.value, "allocation_strategy", local.default_spot_specification.allocation_strategy)
          block_duration_minutes   = lookup(spot_specification.value, "block_duration_minutes", local.default_spot_specification.block_duration_minutes)
          timeout_action           = lookup(spot_specification.value, "timeout_action", local.default_spot_specification.timeout_action)
          timeout_duration_minutes = lookup(spot_specification.value, "timeout_duration_minutes", local.default_spot_specification.timeout_duration_minutes)
        }
      }
    }
  }
}

### cluster/scaling
resource "aws_emr_managed_scaling_policy" "as" {
  for_each   = local.scaling == null ? {} : { emr_managed = local.scaling }
  cluster_id = aws_emr_cluster.cp["enabled"].id
  dynamic "compute_limits" {
    for_each = { for k, v in each.value : k => v if k == "compute_limits" }
    content {
      unit_type                       = lookup(compute_limits.value, "unit_type", local.default_scaling_policy.compute_limits.unit_type)
      minimum_capacity_units          = lookup(compute_limits.value, "minimum_capacity_units", local.default_scaling_policy.compute_limits.minimum_capacity_units)
      maximum_capacity_units          = lookup(compute_limits.value, "maximum_capacity_units", local.default_scaling_policy.compute_limits.maximum_capacity_units)
      maximum_ondemand_capacity_units = lookup(compute_limits.value, "maximum_ondemand_capacity_units", local.default_scaling_policy.compute_limits.maximum_ondemand_capacity_units)
      maximum_core_capacity_units     = lookup(compute_limits.value, "maximum_core_capacity_units", local.default_scaling_policy.compute_limits.maximum_core_capacity_units)
    }
  }
}

### security/policy
resource "aws_iam_role" "studio" {
  for_each = toset(local.studio_enabled ? ["enabled"] : [])
  name     = join("-", [local.name, "studio"])
  tags     = merge(var.tags, local.default-tags)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = format("elasticmapreduce.%s", module.aws.partition.dns_suffix)
      }
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = module.aws.caller.account_id
        }
        ArnLike = {
          "aws:SourceArn" = format("arn:aws:elasticmapreduce:%s:%s:*", module.aws.region.name, module.aws.caller.account_id)
        }
      }
    }]
  })
}

### https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-studio-service-role.html#emr-studio-service-role-permissions-table
resource "aws_iam_role_policy_attachment" "studio" {
  for_each   = toset(local.studio_enabled ? ["enabled"] : [])
  policy_arn = aws_iam_policy.studio["enabled"].arn
  role       = aws_iam_role.studio["enabled"].name
}

resource "aws_iam_policy" "studio" {
  for_each    = toset(local.studio_enabled ? ["enabled"] : [])
  name        = join("-", [local.name, "studio"])
  tags        = merge(var.tags, local.default-tags)
  description = format("Allow an EMR Studio to manage AWS resources")
  policy      = file("${path.module}/templates/studio-policy.tpl")
}

resource "aws_iam_role_policy_attachment" "studio-extra" {
  for_each   = local.studio_enabled ? { for k, v in lookup(var.studio, "policy_arns", []) : k => v } : {}
  policy_arn = each.value
  role       = aws_iam_role.studio["enabled"].name
}

### application/studio
resource "aws_emr_studio" "studio" {
  for_each                    = toset(local.studio_enabled ? ["enabled"] : [])
  name                        = local.name
  tags                        = merge(var.tags, local.default-tags)
  auth_mode                   = lookup(var.studio, "auth_mode", local.default_studio["auth_mode"])
  default_s3_location         = lookup(var.studio, "default_s3_location")
  vpc_id                      = var.vpc
  subnet_ids                  = var.subnets
  service_role                = aws_iam_role.studio["enabled"].arn
  engine_security_group_id    = aws_security_group.studio["engine"].id
  workspace_security_group_id = aws_security_group.studio["workspace"].id
}

### security/firewall
resource "aws_security_group" "studio" {
  for_each = toset(local.studio_enabled ? ["engine", "workspace"] : [])
  name     = join("-", [local.name, "studio", each.key])
  tags     = merge(var.tags, local.default-tags)
  vpc_id   = var.vpc
}

### You must create these security groups when you use the AWS CLI to create a Studio.
### For more details, please refer to this https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-studio-security-groups.html
resource "aws_security_group_rule" "studio-engine-ingress-from-workspace" {
  for_each = toset(local.studio_enabled ? ["enabled"] : [])
  ### Allow traffic from any resources in the Workspace security group for EMR Studio.
  type                     = "ingress"
  security_group_id        = aws_security_group.studio["engine"].id
  from_port                = "18888"
  to_port                  = "18888"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.studio["workspace"].id
}

resource "aws_security_group_rule" "studio-workspace-egress-to-engine" {
  for_each = toset(local.studio_enabled ? ["enabled"] : [])
  ### Allow traffic to any resources in the Engine security group for EMR Studio.
  type                     = "egress"
  security_group_id        = aws_security_group.studio["workspace"].id
  from_port                = "18888"
  to_port                  = "18888"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.studio["engine"].id
}

resource "aws_security_group_rule" "studio-workspace-egress-to-internet" {
  for_each = toset(local.studio_enabled ? ["enabled"] : [])
  ### Allow traffic to the internet to link publicly hosted Git repositories to Workspaces.
  type              = "egress"
  security_group_id = aws_security_group.studio["workspace"].id
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
