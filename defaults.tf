### default values

locals {
  default_master_node_groups = {
    instance_type  = "m5.large"
    instance_count = 1
  }
  default_core_node_groups = {
    instance_type  = "m5.large"
    instance_count = 3
  }
}
