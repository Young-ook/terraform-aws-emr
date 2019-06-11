### Security group for master of emr cluster
resource "aws_security_group" "master" {
  name                   = "${local.master_name}"
  description            = "${local.master_name} EMR SG"
  vpc_id                 = "${var.vpc}"
  revoke_rules_on_delete = true

  tags {
    Name = "${local.master_name}"
  }
}

resource "aws_security_group_rule" "master_ingress_rules" {
  count             = "${length(var.master_ingress_rules)}"
  type              = "ingress"
  cidr_blocks       = ["${element(var.master_ingress_rules[count.index], 0)}"]
  from_port         = "${element(var.master_ingress_rules[count.index], 1)}"
  to_port           = "${element(var.master_ingress_rules[count.index], 2)}"
  protocol          = "${element(var.master_ingress_rules[count.index], 3)}"
  description       = "${element(var.master_ingress_rules[count.index], 4)}"
  security_group_id = "${aws_security_group.master.id}"
}

resource "aws_security_group_rule" "master_egress_rules" {
  count             = "${length(var.master_egress_rules)}"
  type              = "egress"
  cidr_blocks       = ["${element(var.master_egress_rules[count.index], 0)}"]
  from_port         = "${element(var.master_egress_rules[count.index], 1)}"
  to_port           = "${element(var.master_egress_rules[count.index], 2)}"
  protocol          = "${element(var.master_egress_rules[count.index], 3)}"
  description       = "${element(var.master_egress_rules[count.index], 4)}"
  security_group_id = "${aws_security_group.master.id}"
}

### Security group for task runners of emr cluster
resource "aws_security_group" "slave" {
  name                   = "${local.slave_name}"
  description            = "${local.slave_name} EMR SG"
  vpc_id                 = "${var.vpc}"
  revoke_rules_on_delete = true

  tags {
    Name = "${local.slave_name}"
  }
}

resource "aws_security_group_rule" "slave_ingress_rules" {
  count             = "${length(var.slave_ingress_rules)}"
  type              = "ingress"
  cidr_blocks       = ["${element(var.slave_ingress_rules[count.index], 0)}"]
  from_port         = "${element(var.slave_ingress_rules[count.index], 1)}"
  to_port           = "${element(var.slave_ingress_rules[count.index], 2)}"
  protocol          = "${element(var.slave_ingress_rules[count.index], 3)}"
  description       = "${element(var.slave_ingress_rules[count.index], 4)}"
  security_group_id = "${aws_security_group.slave.id}"
}

resource "aws_security_group_rule" "slave_egress_rules" {
  count             = "${length(var.slave_egress_rules)}"
  type              = "egress"
  cidr_blocks       = ["${element(var.slave_egress_rules[count.index], 0)}"]
  from_port         = "${element(var.slave_egress_rules[count.index], 1)}"
  to_port           = "${element(var.slave_egress_rules[count.index], 2)}"
  protocol          = "${element(var.slave_egress_rules[count.index], 3)}"
  description       = "${element(var.slave_egress_rules[count.index], 4)}"
  security_group_id = "${aws_security_group.slave.id}"
}
