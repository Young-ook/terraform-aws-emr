cluster = {
  bootstrap = [
    {
      path = "s3://emr-bootstrap/actions/run-if"
      name = "runif"
      args = ["instance.isMaster=true", "echo running on master node"]
    },
  ]
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
master_node_groups = {}
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
  target_spot_capacity      = 2
  launch_specifications = {
    spot_specification = {
      allocation_strategy      = "capacity-optimized"
      timeout_action           = "TERMINATE_CLUSTER"
      timeout_duration_minutes = 15
    }
  }
  instance_type_configs = [
    {
      instance_type     = "m5.xlarge"
      weighted_capacity = 2
    },
    {
      instance_type     = "m5.2xlarge"
      weighted_capacity = 1
    }
  ]
}
