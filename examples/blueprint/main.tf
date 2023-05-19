### EMR Blueprint

terraform {
  required_version = "~> 1.0"
}

provider "aws" {
  region = var.aws_region
}

module "aws" {
  source  = "Young-ook/spinnaker/aws//modules/aws-partitions"
  version = "2.3.5"
}

### vpc
module "vpc" {
  source  = "Young-ook/vpc/aws"
  version = "1.0.3"
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
  depends_on = [module.vpc]
  source     = "Young-ook/emr/aws//modules/studio"
  version    = "0.0.3"
  name       = var.name
  vpc        = module.vpc.vpc.id
  subnets    = slice(values(module.vpc.subnets[var.use_default_vpc ? "public" : "private"]), 0, 3)
  studio = {
    auth_mode           = "IAM"
    default_s3_location = "s3://${module.s3.bucket.bucket}/data"
    policy_arns = [
      module.s3.policy_arns["read"],
      module.s3.policy_arns["write"],
    ]
  }
}

module "emr-ec2" {
  depends_on          = [module.vpc]
  source              = "Young-ook/emr/aws"
  version             = "0.0.4"
  name                = var.name
  subnets             = slice(values(module.vpc.subnets[var.use_default_vpc ? "public" : "private"]), 0, 3)
  cluster             = var.cluster
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
  kubernetes_version  = var.kubernetes_version
  enable_ssm          = var.enable_ssm
  managed_node_groups = var.managed_node_groups
}

### s3
module "s3" {
  source        = "Young-ook/sagemaker/aws//modules/s3"
  version       = "0.3.4"
  name          = var.name
  tags          = var.tags
  force_destroy = var.force_destroy
  bucket_policy = {
    vpce-only = {
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid = "AllowAccessFromVpcEndpoint"
            Action = [
              "s3:GetObject",
              "s3:PutObject",
              "s3:ListBucket"
            ]
            Effect = "Deny"
            Principal = {
              AWS = flatten([module.aws.caller.account_id, ])
            }
            Resource = [join("/", [module.s3.bucket.arn, "*"]), module.s3.bucket.arn, ]
            Condition = {
              StringNotEquals = {
                "aws:sourceVpce" = module.vpc.vpce.s3.id
              }
            }
          },
          {
            Sid    = "AllowTerraformToReadBuckets"
            Action = "s3:ListBucket"
            Effect = "Allow"
            Principal = {
              AWS = flatten([module.aws.caller.account_id, ])
            }
            Resource = [module.s3.bucket.arn, ]
          }
        ]
      })
    }
  }
  lifecycle_rules = [
    {
      id     = "s3-intelligent-tiering"
      status = "Enabled"
      filter = {
        prefix = ""
      }
      transition = [
        {
          days = 0
          # valid values for 'storage_class':
          #   STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING,
          #   GLACIER, DEEP_ARCHIVE, GLACIER_IR
          storage_class = "INTELLIGENT_TIERING"
        },
      ]
    },
  ]
  intelligent_tiering_archive_rules = [
    {
      state = "Enabled"
      filter = [
        {
          prefix = "logs/"
          tags = {
            priority = "high"
            class    = "blue"
          }
        },
      ]
      tiering = [
        {
          # allowed values for 'access_tier':
          #   ARCHIVE_ACCESS, DEEP_ARCHIVE_ACCESS
          access_tier = "ARCHIVE_ACCESS"
          days        = 125
        },
        {
          access_tier = "DEEP_ARCHIVE_ACCESS"
          days        = 180
        },
      ]
    }
  ]
}
