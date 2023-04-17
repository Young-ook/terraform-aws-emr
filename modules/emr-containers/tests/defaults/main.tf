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

module "eks" {
  source  = "Young-ook/eks/aws"
  version = "2.0.5"
  subnets = values(module.vpc.subnets["public"])
}

module "main" {
  source = "../.."
  container_providers = {
    id = module.eks.cluster.name
  }
}

resource "test_assertions" "pet_name" {
  component = "pet_name"

  check "pet_name" {
    description = "default random pet name"
    condition   = can(regex("^emr", module.main.cluster.name))
  }
}
