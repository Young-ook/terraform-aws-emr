tags = { example = "emr_blueprint" }
primary_node_groups = {
  instance_type_configs = [
    {
      instance_type = "m5.xlarge"
    },
  ]
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
  target_spot_capacity = 2
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
