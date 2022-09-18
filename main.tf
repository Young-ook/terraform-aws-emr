### security/policy
data "aws_iam_policy_document" "cp" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["elasticmapreduce.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cp" {
  name               = local.name
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.cp.json
}

resource "aws_iam_role_policy_attachment" "emr" {
  role       = aws_iam_role.cp.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
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
    #subnet_id                         = var.subnets
    emr_managed_master_security_group = aws_security_group.cp.id
    emr_managed_slave_security_group  = aws_security_group.ng.id
    instance_profile                  = aws_iam_instance_profile.ng.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

### security/policy
data "aws_iam_policy_document" "ng" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ng" {
  name               = join("-", [local.name, "ng"])
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ng.json
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
