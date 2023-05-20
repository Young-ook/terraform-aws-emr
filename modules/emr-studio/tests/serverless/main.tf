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

module "vpc" {
  source  = "Young-ook/vpc/aws"
  version = "1.0.3"
}

module "s3" {
  source  = "Young-ook/sagemaker/aws//modules/s3"
  version = "0.3.4"
}

module "main" {
  source  = "../.."
  vpc     = module.vpc.vpc.id
  subnets = values(module.vpc.subnets["public"])
  studio = {
    auth_mode           = "IAM"
    default_s3_location = "s3://${module.s3.bucket.bucket}/data"
    policy_arns = [
      module.s3.policy_arns["read"],
      module.s3.policy_arns["write"],
    ]
  }
  serverless = {
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
      },
    ]
    maximum_capacity = {
      cpu    = "48 vCPU"
      memory = "144 GB"
    }
  }
}
