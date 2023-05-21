### input variables

### network
variable "vpc" {
  description = "A VPC Id. for an EMR studio"
  type        = string
  default     = null
}

variable "subnets" {
  description = "A list of subnet IDs to deploy an EMR studio"
  type        = list(string)
}

### emr studio
variable "studio" {
  description = "EMR studio configuration"
  default     = {}
}

variable "applications" {
  description = "List of EMR serverless applications"
  default     = []
  validation {
    condition     = var.applications != null
    error_message = "The list of serverless applications must not be null."
  }
}

### description
variable "name" {
  description = "EMR studio name"
  type        = string
  default     = null
}

### tags
variable "tags" {
  description = "The key-value maps for tagging"
  type        = map(string)
  default     = {}
}
