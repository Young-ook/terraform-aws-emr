# EMR

provider "aws" {
  region = var.aws_region
}

# vpc
module "vpc" {
  source  = "Young-ook/vpc/aws"
  version = "1.0.2"
  name    = var.name
  tags    = var.tags
  vpc_config = var.use_default_vpc ? null : {
    azs         = var.azs
    cidr        = "10.10.0.0/16"
    subnet_type = "private"
    single_ngw  = true
  }
}

# vpc
module "emr" {
  source           = "../../"
  name             = var.name
  region           = var.aws_region
  vpc              = module.vpc.vpc.id
  subnets          = slice(values(module.vpc.subnets[var.use_default_vpc ? "public" : "private"]), 0, 3)
  azs              = var.azs
  task_node_groups = var.task_node_groups
}
