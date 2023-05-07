### Amazon EMR Studio

### aws partitions
module "aws" {
  source = "Young-ook/spinnaker/aws//modules/aws-partitions"
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
  name        = join("-", [local.name, "emr-studio"])
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
  subnet_ids                  = var.subnets
  service_role                = aws_iam_role.studio.arn
  engine_security_group_id    = aws_security_group.studio["engine"].id
  workspace_security_group_id = aws_security_group.studio["workspace"].id
}

### security/firewall
resource "aws_security_group" "studio" {
  for_each = toset(["engine", "workspace"])
  name     = join("-", [local.name, "studio", each.key])
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
