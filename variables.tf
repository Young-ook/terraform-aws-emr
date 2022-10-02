### network
variable "subnets" {
  description = "The list of subnet IDs to deploy your EKS cluster"
  type        = list(string)
}

variable "additional_master_security_group" {
  description = "Additional security group for master nodes"
  default     = null
}

variable "additional_slave_security_group" {
  description = "Additional security group for slave nodes"
  default     = null
}

### emr cluster
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

variable "custom_scale_policy" {
  description = "Path to custom rendered scaling policy"
  default     = ""
}

### alert
variable "scale_out_alarms" {
  description = "metric alarm list for autoscaling trigger"
  default = {
    "0" = ["CPUUtilization", "GreaterThanOrEqualToThreshold", "2", "120", "80"]
  }
}

variable "scale_in_alarms" {
  description = "metric alarm list for autoscaling trigger"
  default = {
    "0" = ["CPUUtilization", "LessThanThreshold", "2", "120", "20"]
  }
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
