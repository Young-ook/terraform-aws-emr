# IAM role and policy for ElasticMapReduce cluster

### IAM role policy for EMR cluster
data "aws_iam_policy_document" "svc" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["elasticmapreduce.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "svc" {
  name               = "${local.name}"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.svc.json}"
}

resource "aws_iam_role_policy_attachment" "svc" {
  role       = "${aws_iam_role.svc.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

### IAM instance profiles for EC2 instances in EMR cluster
data "aws_iam_policy_document" "task" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "task" {
  name               = "${local.slave_name}"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.task.json}"
}

resource "aws_iam_role_policy_attachment" "task" {
  role       = "${aws_iam_role.task.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

resource "aws_iam_instance_profile" "task" {
  name = "${local.slave_name}"
  role = "${aws_iam_role.task.name}"
}
