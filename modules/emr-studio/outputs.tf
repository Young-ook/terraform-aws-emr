### output variables

output "studio" {
  description = "The EMR studio attributes"
  value       = aws_emr_studio.studio
}

output "role" {
  description = "The IAM roles for EMR studio"
  value = {
    studio = aws_iam_role.studio
  }
}
