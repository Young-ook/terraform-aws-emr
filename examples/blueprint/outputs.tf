output "vpc" {
  description = "Amazon VPC network"
  value       = module.vpc
}

output "emr" {
  description = "Amazon EMR cluster"
  value = {
    emr-ec2 = module.emr-ec2
    emr-eks = module.emr-eks
  }
}
