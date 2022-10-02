# output variables

output "cluster" {
  description = "The EMR cluster attributes"
  value = {
    control_plane  = aws_emr_cluster.cp
    data_plane     = aws_emr_instance_fleet.dp
    scaling_policy = aws_emr_managed_scaling_policy.as
  }
}

output "role" {
  description = "The generated role of the EMR node group"
  value = {
    name = aws_iam_role.ng.name
    arn  = aws_iam_role.ng.arn
  }
}
