### default values

locals {
  default_master_node_groups = {
    instance_type             = "m5.xlarge"
    target_on_demand_capacity = 1
  }
  default_core_node_groups = {
    instance_type                  = "m5.xlarge"
    provisioned_on_demand_capacity = 1
    provisioned_spot_capacity      = 1
    target_on_demand_capacity      = 1
    target_spot_capacity           = 1
  }
  default_task_node_groups = {
    instance_type                  = "m5.xlarge"
    provisioned_on_demand_capacity = 1
    provisioned_spot_capacity      = 1
    target_on_demand_capacity      = 1
    target_spot_capacity           = 1
  }
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
  default_cluster = {
    release                = "emr-5.36.0"
    applications           = ["Spark", "Hadoop", "Hive"]
    termination_protection = false
    ssh_key                = null
    bootstrap = [
      {
        path = "s3://emr-bootstrap/actions/run-if"
        name = "runif"
        args = ["instance.isMaster=true", "echo running on master node"]
      },
    ]
  }
}
