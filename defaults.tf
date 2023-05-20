### default values

locals {
  default_instance_type_config = {
    bid_price                                  = null
    bid_price_as_percentage_of_on_demand_price = 100
    instance_type                              = "m5.xlarge"
    weighted_capacity                          = 1
    ebs_config = {
      size                 = 100
      type                 = "gp2"
      volumes_per_instance = 1
    }
  }
  default_instance_type_configs = [
    local.default_instance_type_config
  ]
  default_on_demand_specification = {
    # specifies the strategy to use in launching On-Demand instance fleets
    # currently, the only option is lowest-price (the default)
    allocation_strategy = "lowest-price"
  }
  default_spot_specification = {
    # specifies the strategy to use in launching Spot instance fleets
    # currently, the only option is capacity-optimized (the default)
    allocation_strategy      = "capacity-optimized"
    block_duration_minutes   = 0
    timeout_action           = "SWITCH_TO_ON_DEMAND" # valid values: TERMINATE_CLUSTER | SWITCH_TO_ON_DEMAND
    timeout_duration_minutes = 10
  }
  default_primary_node_groups = {
    instance_type             = "m5.xlarge"
    target_on_demand_capacity = 1
    launch_specifications = {
      on_demand_specification = local.default_on_demand_specification
      spot_specification      = null
    }
  }
  default_core_node_groups = {
    instance_type                  = "m5.xlarge"
    provisioned_on_demand_capacity = 1
    provisioned_spot_capacity      = 1
    target_on_demand_capacity      = 1
    target_spot_capacity           = 1
    launch_specifications = {
      on_demand_specification = null
      spot_specification      = local.default_spot_specification
    }
  }
  default_task_node_groups = {
    instance_type                  = "m5.xlarge"
    provisioned_on_demand_capacity = 1
    provisioned_spot_capacity      = 1
    target_on_demand_capacity      = 1
    target_spot_capacity           = 1
    launch_specifications = {
      on_demand_specification = local.default_on_demand_specification
      spot_specification      = local.default_spot_specification
    }
  }
  default_cluster = {
    applications           = ["Spark", "Hadoop", "Hive"]
    bootstrap              = []
    release                = "emr-6.10.0"
    ssh_key                = null
    scaling                = null
    termination_protection = false
  }
  default_scaling_policy = {
    compute_limits = {
      # The unit type used for specifying a managed scaling policy
      # valid values: InstanceFleetUnits, Instances, VCPU
      unit_type                       = "InstanceFleetUnits"
      minimum_capacity_units          = 2
      maximum_capacity_units          = 10
      maximum_ondemand_capacity_units = 2
      maximum_core_capacity_units     = 10
    }
  }
}
