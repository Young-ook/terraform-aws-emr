output "id" {
  value = aws_emr_cluster.cp.id
}

output "svc_role_id" {
  value = aws_iam_role.cp.id
}

output "task_role_id" {
  value = aws_iam_role.ng.id
}
