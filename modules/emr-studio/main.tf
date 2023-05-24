### Amazon EMR Studio

### aws partitions
module "aws" {
  source = "Young-ook/spinnaker/aws//modules/aws-partitions"
}

locals {
  serverless_enabled = length(var.applications) > 0 ? true : false
}

### security/policy
resource "aws_iam_role" "studio" {
  name = local.name
  tags = merge(var.tags, local.default-tags)
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
  policy_arn = aws_iam_policy.studio.arn
  role       = aws_iam_role.studio.name
}

resource "aws_iam_policy" "studio" {
  name        = local.name
  tags        = merge(var.tags, local.default-tags)
  description = format("Allow an EMR Studio to manage AWS resources")
  policy      = file("${path.module}/templates/studio-policy.tpl")
}

resource "aws_iam_role_policy_attachment" "extra" {
  for_each   = { for k, v in lookup(var.studio, "policy_arns", []) : k => v }
  policy_arn = each.value
  role       = aws_iam_role.studio.name
}

### application/studio
resource "aws_emr_studio" "studio" {
  name                        = local.name
  tags                        = merge(var.tags, local.default-tags)
  auth_mode                   = lookup(var.studio, "auth_mode", local.default_studio["auth_mode"])
  default_s3_location         = lookup(var.studio, "default_s3_location")
  vpc_id                      = var.vpc
  subnet_ids                  = try(var.subnets, null)
  service_role                = aws_iam_role.studio.arn
  engine_security_group_id    = aws_security_group.studio["engine"].id
  workspace_security_group_id = aws_security_group.studio["workspace"].id
}

### security/firewall
resource "aws_security_group" "studio" {
  for_each = toset(["engine", "workspace"])
  name     = join("-", [local.name, each.key])
  tags     = merge(var.tags, local.default-tags)
  vpc_id   = var.vpc
}

### You must create these security groups when you use the AWS CLI to create a Studio.
### For more details, please refer to this https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-studio-security-groups.html
resource "aws_security_group_rule" "studio-engine-ingress-from-workspace" {
  ### Allow traffic from any resources in the Workspace security group for EMR Studio.
  type                     = "ingress"
  security_group_id        = aws_security_group.studio["engine"].id
  from_port                = "18888"
  to_port                  = "18888"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.studio["workspace"].id
}

resource "aws_security_group_rule" "studio-workspace-egress-to-engine" {
  ### Allow traffic to any resources in the Engine security group for EMR Studio.
  type                     = "egress"
  security_group_id        = aws_security_group.studio["workspace"].id
  from_port                = "18888"
  to_port                  = "18888"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.studio["engine"].id
}

resource "aws_security_group_rule" "studio-workspace-egress-to-internet" {
  ### Allow traffic to the internet to link publicly hosted Git repositories to Workspaces.
  type              = "egress"
  security_group_id = aws_security_group.studio["workspace"].id
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

### EMR Studio is the user console that you can use to manage your EMR Serverless applications.
### If an EMR Studio doesn't exist in your account when you create your first EMR Serverless application,
### AWS will automatically create one for you. For more details, here is the Amazon EMR serverless user guide.
### https://docs.aws.amazon.com/emr/latest/EMR-Serverless-UserGuide/emr-serverless.html
### cluster/serverless
resource "aws_emrserverless_application" "apps" {
  depends_on    = [aws_emr_studio.studio]
  for_each      = { for app in var.applications : app.name => app }
  name          = each.key
  tags          = merge(var.tags, local.default-tags, { Name = each.key })
  architecture  = lookup(each.value, "architecture", local.default_cluster["architecture"])
  release_label = lookup(each.value, "release", local.default_cluster["release"])
  type          = lookup(each.value, "type", local.default_cluster["type"])

  network_configuration {
    security_group_ids = [aws_security_group.studio["workspace"].id]
    subnet_ids         = try(var.subnets, null)
  }

  dynamic "auto_start_configuration" {
    for_each = [try(each.value["auto_start_config"], local.default_cluster.auto_start_config)]
    content {
      enabled = try(auto_start_configuration.value.enabled, null)
    }
  }

  dynamic "auto_stop_configuration" {
    for_each = [try(each.value["auto_stop_config"], local.default_cluster.auto_stop_config)]
    content {
      enabled              = try(auto_stop_configuration.value.enabled, null)
      idle_timeout_minutes = try(auto_stop_configuration.value.idle_timeout_minutes, null)
    }
  }

  dynamic "initial_capacity" {
    for_each = { for k, v in try(each.value["initial_capacity"], local.default_initial_capacity) : k => v }
    content {
      initial_capacity_type = initial_capacity.value["initial_capacity_type"]
      dynamic "initial_capacity_config" {
        for_each = can(initial_capacity.value["initial_capacity_config"]) ? [initial_capacity.value["initial_capacity_config"]] : []
        content {
          worker_count = try(initial_capacity_config.value["worker_count"], local.default_instance_count)
          dynamic "worker_configuration" {
            for_each = can(initial_capacity_config.value["worker_config"]) ? [initial_capacity_config.value["worker_config"]] : []
            content {
              cpu    = try(worker_configuration.value["cpu"], local.default_instance_capacity["cpu"])
              disk   = try(worker_configuration.value["disk"], local.default_instance_capacity["disk"])
              memory = try(worker_configuration.value["memory"], local.default_instance_capacity["memory"])
            }
          }
        }
      }
    }
  }

  dynamic "maximum_capacity" {
    for_each = can(each.value["maximum_capacity"]) ? [each.value["maximum_capacity"]] : []
    content {
      cpu    = try(maximum_capacity.value["cpu"], local.default_maximum_capacity["cpu"])
      disk   = try(maximum_capacity.value["disk"], local.default_maximum_capacity["disk"])
      memory = try(maximum_capacity.value["memory"], local.default_maximum_capacity["memory"])
    }
  }
}
