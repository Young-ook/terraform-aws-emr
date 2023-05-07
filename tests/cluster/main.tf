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
  cluster = {
    #  bootstrap = [
    #    {
    #      path = "s3://emr-bootstrap/actions/run-if"
    #      name = "runif"
    #      args = ["instance.isMaster=true", "echo running on master node"]
    #    },
    #  ]
    scaling = {
      compute_limits = {
        # The unit type used for specifying a managed scaling policy
        # valid values: InstanceFleetUnits, Instances, VCPU
        unit_type              = "InstanceFleetUnits"
        minimum_capacity_units = 2
        maximum_capacity_units = 10
      }
    }
  }
}

resource "test_assertions" "pet_name" {
  component = "pet_name"

  check "pet_name" {
    description = "default random pet name"
    condition   = can(regex("^emr", module.main.cluster["enabled"].control_plane.name))
  }
}
