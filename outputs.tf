output "id" {
  value = "${aws_emr_cluster.emr.id}"
}

output "svc_role_id" {
  value = "${aws_iam_role.svc.id}"
}

output "task_role_id" {
  value = "${aws_iam_role.task.id}"
}
