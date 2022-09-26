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
}
