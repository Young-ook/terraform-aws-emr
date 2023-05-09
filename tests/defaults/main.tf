terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }
  }
}

module "vpc" {
  source  = "Young-ook/vpc/aws"
  version = "1.0.3"
}

module "main" {
  source  = "../.."
  subnets = values(module.vpc.subnets["public"])
}

resource "test_assertions" "null" {
  component = "null"

  check "null_cluster" {
    description = "check if the default emr cluster is null"
    condition   = !can(module.main.cluster.enabled)
  }
}
