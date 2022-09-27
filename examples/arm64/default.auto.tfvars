aws_region      = "ap-northeast-2"
azs             = ["ap-northeast-2a", "ap-northeast-2c", "ap-northeast-2d"]
use_default_vpc = true
master_node_groups = {
  instance_type_configs = [
    {
      instance_type = "m6g.xlarge"
    },
  ]
}
core_node_groups = {
  target_on_demand_capacity = 1
  instance_type_configs = [
    {
      instance_type = "m6g.xlarge"
    },
  ]
}
task_node_groups = {
  target_spot_capacity = 2
  instance_type_configs = [
    {
      instance_type     = "m6g.xlarge"
      weighted_capacity = 2
    },
    {
      instance_type     = "m6g.2xlarge"
      weighted_capacity = 1
    }
  ]
}
