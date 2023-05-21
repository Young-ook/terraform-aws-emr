### default variables

locals {
  default_studio = {
    # Specifies whether the Studio authenticates users using IAM or Amazon Web Services SSO.
    # Valid values are SSO or IAM.
    auth_mode = "IAM"
  }
  default_cluster = {
    # The CPU architecture of an application.
    # Valid values are ARM64, X86_64
    architecture = "X86_64"
    release      = "emr-6.6.0"
    type         = "spark"
    auto_start_config = {
      enabled = null
    }
    auto_stop_config = {
      enabled              = null
      idle_timeout_minutes = null
    }
  }
  default_initial_capacity = [
    {
      # The worker type for an analytics framework.
      # For Spark applications, the key can either be set to Driver or Executor.
      # For Hive applications, it can be set to HiveDriver or TezTask.
      initial_capacity_type = "Driver"
      initial_capacity_config = {
        worker_count  = local.default_instance_count
        worker_config = local.default_instance_capacity
      }
    },
    {
      initial_capacity_type = "Executor"
      initial_capacity_config = {
        worker_count  = local.default_instance_count
        worker_config = local.default_instance_capacity
      }
    }
  ]
  default_instance_count = 1
  default_instance_capacity = {
    cpu    = "4 vCPU"
    disk   = "64 GB"
    memory = "12 GB"
  }
  default_maximum_capacity = {
    cpu    = "8 vCPU"
    disk   = "128 GB"
    memory = "24 GB"
  }
}
