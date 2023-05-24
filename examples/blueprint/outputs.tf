output "emr" {
  description = "Amazon EMR cluster"
  value = {
    emr-ec2 = module.emr-ec2
    emr-eks = module.emr-eks
  }
}

output "studio" {
  description = "Amazon EMR studio"
  value       = module.emr-studio
}

output "apps" {
  description = "Bash script to run a basic pyspark job on your virtual EMR cluster"
  value = {
    pyspark_pi = join(" ", [
      "bash -e",
      format("%s/apps/pi/basic-pyspark-job.sh", path.module),
      format("-c %s", module.emr-eks.cluster["id"]),
      format("-r %s", module.emr-eks.role["job"].arn),
    ])
  }
}
