### output variables

output "cluster" {
  description = "Redshift cluster"
  value       = aws_redshift_cluster.dw
}
