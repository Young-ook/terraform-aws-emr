output "vpc" {
  description = "Amazon VPC network"
  value       = module.vpc
}

output "emr" {
  description = "Amazon EMR cluster"
  value       = module.emr
}
