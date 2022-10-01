aws_region      = "ap-northeast-2"
azs             = ["ap-northeast-2a", "ap-northeast-2c", "ap-northeast-2d"]
use_default_vpc = true
task_node_groups = {
  target_on_demand_capacity = 1
  target_spot_capacity      = 2
  instance_type_configs = [
    {
      instance_type     = "m5.xlarge"
      weighted_capacity = 2
    },
    {
      instance_type     = "m5.4xlarge"
      weighted_capacity = 1
    }
  ]
}