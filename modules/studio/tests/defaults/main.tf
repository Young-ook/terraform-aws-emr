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
}
