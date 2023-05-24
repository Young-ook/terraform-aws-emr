terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }
  }
}

module "aws" {
  source = "Young-ook/spinnaker/aws//modules/aws-partitions"
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "Young-ook/vpc/aws"
  version = "1.0.3"
  vpc_config = {
    azs         = data.aws_availability_zones.available.zone_ids
    cidr        = "10.10.0.0/16"
    subnet_type = "private"
    single_ngw  = true
  }
}

module "s3" {
  source  = "Young-ook/sagemaker/aws//modules/s3"
  version = "0.3.4"
}

module "main" {
  source  = "../.."
  vpc     = module.vpc.vpc.id
  subnets = values(module.vpc.subnets["private"])
  studio = {
    auth_mode           = "IAM"
    default_s3_location = "s3://${module.s3.bucket.bucket}/data"
    policy_arns = [
      module.s3.policy_arns["read"],
      module.s3.policy_arns["write"],
    ]
  }
  applications = [
    {
      name = "default-serverless"
    },
    {
      name = "custom-spark"
      initial_capacity = [
        {
          initial_capacity_type = "Driver"
          initial_capacity_config = {
            worker_count = 2
            worker_configuration = {
              cpu    = "4 vCPU"
              memory = "12 GB"
            }
          }
        },
        {
          initial_capacity_type = "Executor"
          initial_capacity_config = {
            worker_count = 2
            worker_configuration = {
              cpu    = "8 vCPU"
              disk   = "64 GB"
              memory = "24 GB"
            }
          }
        }
      ]
      maximum_capacity = {
        cpu    = "48 vCPU"
        memory = "144 GB"
      }
    },
    {
      name = "custom-spark-withonly-init-config"
      initial_capacity = [
        {
          initial_capacity_type = "Driver"
          initial_capacity_config = {
            worker_count = 1
            worker_configuration = {
              cpu    = "4 vCPU"
              disk   = "64 GB"
              memory = "12 GB"
            }
          }
        },
      ]
    },
  ]
}
