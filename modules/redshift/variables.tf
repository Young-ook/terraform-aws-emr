### input variables

### network
variable "vpc" {
  description = "The VPC ID to deploy the cluster"
  type        = string
}

variable "cidrs" {
  description = "The list of CIDR blocks to allow ingress traffic for db access"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "The list of subnet IDs to deploy the cluster"
  type        = list(string)
}

### redshift cluster
#  [CAUTION] Changing the snapshot ID. will force a new resource.
#
variable "cluster" {
  description = "Redshift cluster definition"
  default     = {}
}

### description
variable "name" {
  description = "Module instance name"
  type        = string
  default     = null
}

### tags
variable "tags" {
  description = "The key-value maps for tagging"
  type        = map(string)
  default     = {}
}
