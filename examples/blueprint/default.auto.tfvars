tags = { example = "datalake_blueprint" }

### emr cluster configuration
emr_cluster = {
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
}

### eks cluster configuration
eks_cluster = {
  kubernetes_version = "1.27"
  managed_node_groups = [
    {
      name          = "spark"
      desired_size  = 3
      min_size      = 3
      max_size      = 9
      instance_type = "m5.xlarge"
    },
  ]
}

### redshift cluster configuration
redshift_cluster = {
  usage_limits = [
    {
      # period: daily, weekly, monthly. The time period that the amount applies to. A weekly period begins on Sunday.
      # amount: The limit amount. If time-based, this amount is in minutes. If data-based, this amount is in terabytes (TB).
      # feature_type: spectrum, concurrency-scaling, cross-region-datasharing
      # limit_type: time, data-scanned
      #
      # limit_type is depending on the feature_type. If feature_type is spectrum, the limit_type must be data-scanned.
      # If feature_type is concurrency-scaling, then limit_type must be time. And if feature_type is cross-region-datasharing,
      # then limit_type must be data-scanned.

      period       = "weekly"
      amount       = 1
      feature_type = "spectrum"
      limit_type   = "data-scanned"
    },
    {
      amount       = 1
      feature_type = "concurrency-scaling"
      limit_type   = "time"
    }
  ]
}
