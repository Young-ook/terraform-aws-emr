# emr.tf
# elastic map-reduce cluster

### Auto scaling policy to apply on instance group
data "template_file" "scale-policy" {
  template = file("${path.module}/scale-policy.tpl")
}

### EMR Cluster
resource "aws_emr_cluster" "emr" {
  name                              = local.name
  release_label                     = var.release
  applications                      = concat(var.applications)
  termination_protection            = false
  keep_job_flow_alive_when_no_steps = true
  service_role                      = aws_iam_role.svc.arn
  #bootstrap_action                 = var.bootstrap_action

  ec2_attributes {
    #subnet_id                         = "${var.subnet}"
    emr_managed_master_security_group = aws_security_group.master.id
    emr_managed_slave_security_group  = aws_security_group.slave.id
    instance_profile                  = aws_iam_instance_profile.task.arn
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    { "Name" = local.name },
  )
}
