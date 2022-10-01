### aws partitions
module "aws" {
  source = "Young-ook/spinnaker/aws//modules/aws-partitions"
}

### security/policy
resource "aws_iam_role" "cp" {
  name = join("-", [local.name, "cp"])
  tags = merge(local.default-tags, var.tags)
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
  role       = aws_iam_role.cp.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

resource "aws_iam_role" "ng" {
  name = join("-", [local.name, "ng"])
  tags = merge(local.default-tags, var.tags)
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
  role       = aws_iam_role.ng.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

resource "aws_iam_instance_profile" "ng" {
  name = join("-", [local.name, "ng"])
  role = aws_iam_role.ng.name
}

### cluster/control
data "template_file" "scale-policy" {
  template = file("${path.module}/scale-policy.tpl")
}

resource "aws_emr_cluster" "cp" {
  name                              = local.name
  tags                              = merge(local.default-tags, var.tags)
  service_role                      = aws_iam_role.cp.arn
  release_label                     = lookup(var.cluster, "release", local.default_cluster.release)
  applications                      = concat(lookup(var.cluster, "applications", local.default_cluster.applications))
  termination_protection            = lookup(var.cluster, "termination_protections", local.default_cluster.termination_protection)
  keep_job_flow_alive_when_no_steps = true

  ec2_attributes {
    subnet_ids                        = var.subnets
    additional_master_security_groups = var.additional_master_security_group
    additional_slave_security_groups  = var.additional_slave_security_group
    instance_profile                  = aws_iam_instance_profile.ng.arn
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
  cluster_id = aws_emr_cluster.cp.id
  name       = join("-", [local.name, "task-fleet"])

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

  target_on_demand_capacity = lookup(var.task_node_groups, "target_on_demand_capacity", local.default_task_node_groups.target_on_demand_capacity)
  target_spot_capacity      = lookup(var.task_node_groups, "target_spot_capacity", local.default_task_node_groups.target_spot_capacity)
}
