# AWS EMR

## Using module
You can use this module like as below example.


```
module "your_emr" {
  source  = "youngookkim/emr/aws"
  version = "v1.0.0"

  name                    = "your_emr"
  stack                   = "dev"
  region                  = "us-east-1"
  vpc                     = "#{var.vpc_id}"
  subnets                 = "${var.subnets}"
  azs                     = "${var.azs}"
  ssh_key                 = "your-master-key"
  instance_type           = "m5.xlarge"
  desired_capacity        = "3"
  master_ingress_rules    = "${map("0", list("10.0.0.0/8", var.your_app_port, var.your_app_port, "tcp"))}"
  slave_ingress_rules     = "${map("0", list("10.0.0.0/8", var.your_app_port, var.your_app_port, "tcp"))}"
}
```

## How to add your own IAM policy using output of module
if you want to attach your customized IAM policy to apply it to instances which are created in module, you can use output variable of servergroup module that it is named as `role_id`

```
resource "aws_iam_role_policy" "your_app_jobexec" {
  name   = "your_emr-${var.stack}-jobexec"
  policy = "${data.aws_iam_policy_document.emr_jobexec.json}"
  role   = "${module.your_emr.task_role_id}"
}
```
