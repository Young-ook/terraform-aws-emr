### input variables

### network
variable "subnets" {
  description = "The list of subnet IDs to deploy your EMR cluster"
  type        = list(string)
}

variable "additional_primary_security_group" {
  description = "Additional security group for primary nodes"
  default     = null
}

variable "additional_slave_security_group" {
  description = "Additional security group for slave nodes"
  default     = null
}

### emr cluster
variable "cluster" {
  description = "EMR cluster control plane configuration"
  default     = null
}

variable "primary_node_groups" {
  description = "EMR primary node groups configuration"
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

variable "custom_scale_policy" {
  description = "Path to custom rendered scaling policy"
  default     = ""
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
