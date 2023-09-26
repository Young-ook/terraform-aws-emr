### EMR Blueprint

terraform {
  required_version = "~> 1.0"
}

provider "aws" {
  region = var.aws_region
}

### datalake
module "datalake" {
  source = "./datalake"
  vpce   = module.vpc.vpce.s3.id
}

### vpc
module "vpc" {
  source  = "Young-ook/vpc/aws"
  version = "1.0.5"
  name    = var.name
  tags    = var.tags
  vpc_config = var.use_default_vpc ? null : {
    azs         = var.azs
    cidr        = "10.10.0.0/16"
    subnet_type = "private"
    single_ngw  = true
  }
  vpce_config = [
    {
      service             = "s3"
      type                = "Interface"
      private_dns_enabled = false
    },
  ]
}

### emr
module "emr-studio" {
  depends_on = [module.vpc, module.datalake]
  source     = "Young-ook/emr/aws//modules/emr-studio"
  version    = "0.0.4"
  name       = var.name
  vpc        = module.vpc.vpc.id
  subnets    = slice(values(module.vpc.subnets[var.use_default_vpc ? "public" : "private"]), 0, 3)
  studio = {
    auth_mode           = "IAM"
    default_s3_location = "s3://${module.datalake.s3.bucket.bucket}/data"
    policy_arns = [
      module.datalake.s3.policy_arns["read"],
      module.datalake.s3.policy_arns["write"],
    ]
  }
}

module "emr-ec2" {
  depends_on          = [module.vpc]
  source              = "Young-ook/emr/aws"
  version             = "0.0.4"
  name                = var.name
  subnets             = slice(values(module.vpc.subnets[var.use_default_vpc ? "public" : "private"]), 0, 3)
  cluster             = var.emr_cluster
  primary_node_groups = var.primary_node_groups
  core_node_groups    = var.core_node_groups
  task_node_groups    = var.task_node_groups
}

module "emr-eks" {
  depends_on = [module.eks]
  source     = "Young-ook/emr/aws//modules/emr-containers"
  version    = "0.0.2"
  name       = module.eks.cluster.name
  container_providers = {
    id        = module.eks.cluster.name
    namespace = "default"
  }
}

module "eks" {
  source              = "Young-ook/eks/aws"
  version             = "2.0.3"
  name                = var.name
  tags                = var.tags
  subnets             = slice(values(module.vpc.subnets[var.use_default_vpc ? "public" : "private"]), 0, 3)
  kubernetes_version  = "1.27"
  enable_ssm          = true
  managed_node_groups = var.managed_node_groups
}

### redshift
module "redshift" {
  depends_on = [module.vpc]
  source     = "../../modules/redshift"
  name       = var.name
  tags       = var.tags
  vpc        = module.vpc.vpc.id
  subnets    = slice(values(module.vpc.subnets[var.use_default_vpc ? "public" : "private"]), 0, 3)
  cidrs      = [module.vpc.vpc.cidr_block]
  cluster    = var.redshift_cluster
}

### application/workbench
module "ec2" {
  source     = "Young-ook/ssm/aws"
  version    = "1.0.5"
  name       = var.name
  tags       = var.tags
  subnets    = slice(values(module.vpc.subnets[var.use_default_vpc ? "public" : "private"]), 0, 3)
  node_groups = [
    {
      name          = "workbench"
      min_size      = 1
      max_size      = 1
      desired_size  = 1
      instance_type = "m6i.large"
      tags          = { purpose = "workbench" }
    },
    {
      name          = "kinesis"
      min_size      = 1
      max_size      = 1
      desired_size  = 1
      instance_type = "t3.large"
      user_data     = "yum update -y && yum install -y aws-kinesis-agent"
      tags          = { purpose = "publish logs" }
      policy_arns   = [module.datalake.policy.kinesis-firehose-write]
    },
  ]
}
