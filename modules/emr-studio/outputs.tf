### output variables

output "studio" {
  description = "The EMR studio attributes"
  value       = aws_emr_studio.studio
}

output "applications" {
  description = "The EMR serverless application attributes"
  value       = aws_emrserverless_application.apps
}

output "role" {
  description = "The IAM roles for EMR studio"
  value = {
    studio = aws_iam_role.studio
  }
}
