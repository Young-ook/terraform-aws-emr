# Variables for providing to module fixture codes

### network
variable "aws_region" {
  description = "The aws region to deploy"
  type        = string
  default     = "us-east-1"
}

variable "use_default_vpc" {
  description = "A feature flag for whether to use default vpc"
  type        = bool
}

variable "azs" {
  description = "A list of availability zones for the vpc to deploy resources"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1c", "us-east-1d"]
}

### cluster
variable "cluster" {
  description = "EMR cluster control plane configuration"
  default     = {}
}

variable "master_node_groups" {
  description = "EMR master node groups configuration"
  default     = {}
}

variable "core_node_groups" {
  description = "EMR core node groups configuration"
  default     = {}
}

variable "task_node_groups" {
  description = "EMR task node groups configuration"
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
