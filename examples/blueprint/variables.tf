### network
variable "aws_region" {
  description = "The aws region to deploy"
  type        = string
  default     = "ap-northeast-2"
}

variable "use_default_vpc" {
  description = "A feature flag for whether to use default vpc"
  type        = bool
  default     = false
}

variable "azs" {
  description = "A list of availability zones for the vpc to deploy resources"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c", "ap-northeast-2d"]
}

### emr
variable "emr_cluster" {
  description = "EMR cluster control plane configuration"
  default     = {}
}

### kubernetes
variable "managed_node_groups" {
  description = "Amazon managed node groups definition"
  default     = []
}

### redshift
variable "redshift_cluster" {
  description = "Redshift cluster definition"
  default     = {}
}

### description
variable "name" {
  description = "The logical name of the module instance"
  type        = string
  default     = null
}

### tags
variable "tags" {
  description = "The key-value maps for tagging"
  type        = map(string)
  default     = {}
}
