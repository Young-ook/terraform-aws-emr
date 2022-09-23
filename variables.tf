### Elastic MapReduce 
variable "release" {
  description = "EMR release version"
  default     = "emr-5.36.0"
}

variable "applications" {
  description = "List of EMR applications"
  type        = list(string)
  default     = ["Spark", "Hadoop", "Hive"]
}

variable "ssh_key" {
  description = "The key name to SSH into instances with"
  default     = "your-master-key"
}

variable "bootstrap_action" {
  description = "definition of bootstrap action"
  default = [
    {
      path = "s3://emr-bootstrap/actions/run-if"
      name = "runif"
      args = ["instance.isMaster=true", "echo running on master node"]
    },
  ]
}

### network
variable "subnets" {
  description = "The list of subnet IDs to deploy your EKS cluster"
  type        = list(string)
}

### emr cluster
variable "cluster" {
  description = "EMR cluster configuration"
  default     = {}
}

variable "core_node_groups" {
  description = "EMR core node groups configuration"
  default     = {}
}

variable "instance_groups" {
  description = "list of instance groups"
  default = [
    {
      name           = "MasterInstanceGroup"
      instance_role  = "MASTER" // Valid values are MASTER, CORE, and TASK.
      instance_type  = "c4.large"
      instance_count = "1"
    },
    {
      name           = "CoreInstanceGroup"
      instance_role  = "CORE"
      instance_type  = "c4.large"
      instance_count = "1"
      bid_price      = "0.30"
      ebs_config = [{
        size                 = "40"
        type                 = "gp2"
        volumes_per_instance = 1
      }]
    },
  ]
}

variable "master_ingress_rules" {
  description = "ingress list for security group allows"
  default     = {}
}

variable "master_egress_rules" {
  description = "egress list for security group allows"
  default = {
    "0" = ["0.0.0.0/0", "443", "443", "tcp", "https"]
    "1" = ["0.0.0.0/0", "123", "123", "udp", "time sync"]
  }
}

variable "slave_ingress_rules" {
  description = "ingress list for security group allows"
  default     = {}
}

variable "slave_egress_rules" {
  description = "egress list for security group allows"
  default = {
    "0" = ["0.0.0.0/0", "80", "80", "tcp", "http"]
    "1" = ["0.0.0.0/0", "443", "443", "tcp", "https"]
    "2" = ["0.0.0.0/0", "123", "123", "udp", "time sync"]
  }
}

variable "custom_scale_policy" {
  description = "Path to custom rendered scaling policy"
  default     = ""
}

### Alarm
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

### General
variable "region" {
  description = "The AWS region to deploy the shard storage layer into"
  type        = string
}

variable "vpc" {
  description = "The AWS ID of the VPC this shard is being deployed into"
  type        = string
}

variable "azs" {
  description = "A comma-delimited list of availability zones for the VPC"
  type        = list(string)
}

### credentials
variable "aws_profile" {
  description = "The name of profile of AWS credential to apply this terraform module to aws env"
  default     = "default"
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
