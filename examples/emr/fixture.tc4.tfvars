aws_region      = "ap-northeast-2"
azs             = ["ap-northeast-2a", "ap-northeast-2c", "ap-northeast-2d"]
use_default_vpc = false
name            = "emr-tc4-as-with-custom-vpc"
cluster = {
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
core_node_groups = {
  instance_type_configs = [
    {
      instance_type     = "m5.xlarge"
      weighted_capacity = 2
    },
  ]
}
task_node_groups = {
  target_on_demand_capacity = 1
  target_spot_capacity      = 1
}
tags = {
  case-number = "tc4"
  case        = "emr-managed-autoscaling, custom-vpc"
}
