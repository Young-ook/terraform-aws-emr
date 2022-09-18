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

### security/network
resource "aws_security_group" "cp" {
  name                   = join("-", [local.name, "cp"])
  tags                   = merge(local.default-tags, var.tags)
  description            = format("%s EMR SG", join("-", [local.name, "cp"]))
  vpc_id                 = var.vpc
  revoke_rules_on_delete = true
}

resource "aws_security_group_rule" "master_ingress_rules" {
  count             = length(var.master_ingress_rules)
  type              = "ingress"
  cidr_blocks       = ["${element(var.master_ingress_rules[count.index], 0)}"]
  from_port         = element(var.master_ingress_rules[count.index], 1)
  to_port           = element(var.master_ingress_rules[count.index], 2)
  protocol          = element(var.master_ingress_rules[count.index], 3)
  description       = element(var.master_ingress_rules[count.index], 4)
  security_group_id = aws_security_group.cp.id
}

resource "aws_security_group_rule" "master_egress_rules" {
  count             = length(var.master_egress_rules)
  type              = "egress"
  cidr_blocks       = ["${element(var.master_egress_rules[count.index], 0)}"]
  from_port         = element(var.master_egress_rules[count.index], 1)
  to_port           = element(var.master_egress_rules[count.index], 2)
  protocol          = element(var.master_egress_rules[count.index], 3)
  description       = element(var.master_egress_rules[count.index], 4)
  security_group_id = aws_security_group.cp.id
}

### cluster/control
data "template_file" "scale-policy" {
  template = file("${path.module}/scale-policy.tpl")
}

locals {
  master_node_groups = lookup(var.cluster, "master_node_groups", local.default_master_node_groups)
  core_node_groups   = lookup(var.cluster, "core_node_groups", local.default_core_node_groups)
}

resource "aws_emr_cluster" "cp" {
  name                              = local.name
  tags                              = merge(local.default-tags, var.tags)
  release_label                     = var.release
  applications                      = concat(var.applications)
  termination_protection            = false
  keep_job_flow_alive_when_no_steps = true
  service_role                      = aws_iam_role.cp.arn
  #bootstrap_action                 = var.bootstrap_action

  ec2_attributes {
    subnet_ids                        = var.subnets
    additional_master_security_groups = aws_security_group.cp.id
    additional_slave_security_groups  = aws_security_group.ng.id
    instance_profile                  = aws_iam_instance_profile.ng.arn
  }

  master_instance_fleet {
    name = "master node instance fleet"
    instance_type_configs {
      instance_type = lookup(local.master_node_groups, "instance_type", local.default_master_node_groups.instance_type)
    }
    launch_specifications {
      on_demand_specification {
        allocation_strategy = "lowest-price"
      }
    }
    target_on_demand_capacity = lookup(local.master_node_groups, "instance_count", local.default_master_node_groups.instance_count)
  }

  core_instance_fleet {
    name                      = "core node instance fleet"
    target_on_demand_capacity = 1
    target_spot_capacity      = 1
    instance_type_configs {
      bid_price_as_percentage_of_on_demand_price = 100
      ebs_config {
        size                 = 100
        type                 = "gp2"
        volumes_per_instance = 1
      }
      instance_type     = "m5.xlarge"
      weighted_capacity = 1
    }
    launch_specifications {
      spot_specification {
        allocation_strategy      = "capacity-optimized"
        block_duration_minutes   = 0
        timeout_action           = "SWITCH_TO_ON_DEMAND"
        timeout_duration_minutes = 10
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

### security/network
resource "aws_security_group" "ng" {
  name = join("-", [local.name, "ng"])
  tags = merge(local.default-tags, var.tags)

  description            = format("%s EMR SG", join("-", [local.name, "ng"]))
  vpc_id                 = var.vpc
  revoke_rules_on_delete = true
}

resource "aws_security_group_rule" "slave_ingress_rules" {
  count             = length(var.slave_ingress_rules)
  type              = "ingress"
  cidr_blocks       = ["${element(var.slave_ingress_rules[count.index], 0)}"]
  from_port         = element(var.slave_ingress_rules[count.index], 1)
  to_port           = element(var.slave_ingress_rules[count.index], 2)
  protocol          = element(var.slave_ingress_rules[count.index], 3)
  description       = element(var.slave_ingress_rules[count.index], 4)
  security_group_id = aws_security_group.ng.id
}

resource "aws_security_group_rule" "slave_egress_rules" {
  count             = length(var.slave_egress_rules)
  type              = "egress"
  cidr_blocks       = ["${element(var.slave_egress_rules[count.index], 0)}"]
  from_port         = element(var.slave_egress_rules[count.index], 1)
  to_port           = element(var.slave_egress_rules[count.index], 2)
  protocol          = element(var.slave_egress_rules[count.index], 3)
  description       = element(var.slave_egress_rules[count.index], 4)
  security_group_id = aws_security_group.ng.id
}
