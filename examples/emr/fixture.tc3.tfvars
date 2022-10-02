aws_region      = "ap-northeast-2"
azs             = ["ap-northeast-2a", "ap-northeast-2c", "ap-northeast-2d"]
use_default_vpc = true
cluster = {
  ssh_key = "yourkey"
  bootstrap = [
    {
      path = "s3://emr-bootstrap/actions/run-if"
      name = "runif"
      args = ["instance.isMaster=true", "echo running on master node"]
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
  target_on_demand_capacity = 1
  target_spot_capacity      = 1
}
