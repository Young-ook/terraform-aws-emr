### default values

module "aws" {
  source = "Young-ook/spinnaker/aws//modules/aws-partitions"
}

locals {
  default_cluster = {
    mode                                 = "provisioned" # allowed values: provisioned | serverless
    family                               = "redshift-1.0"
    version                              = "1.0"
    port                                 = "5439"
    database                             = "yourdb"
    user                                 = "yourid"
    encrypted                            = false
    elastic_ip                           = null
    publicly_accessible                  = false
    allow_version_upgrade                = true
    enhanced_vpc_routing                 = false
    availability_zone                    = null
    availability_zone_relocation_enabled = false
    skip_final_snapshot                  = true
    snapshot_id                          = null
    automated_snapshot_retention_period  = 7
    manual_snapshot_retention_period     = 7
    apply_immediately                    = false
    number_of_nodes                      = 1
    node_type                            = "dc2.large"
    owner_account                        = module.aws.caller.account_id
    cluster_parameters                   = {}
    scaling = {
      auto_pause               = true
      max_capacity             = 128
      min_capacity             = 1
      seconds_until_auto_pause = 300
      timeout_action           = "ForceApplyCapacityChange"
    }
  }
}
