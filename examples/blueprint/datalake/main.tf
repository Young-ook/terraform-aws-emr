### aws partitions
module "aws" {
  source = "Young-ook/spinnaker/aws//modules/aws-partitions"
}

locals {
  # The dataset used in this example consists of Medicare-Provider payment data downloaded from two Data.CMS.gov sites:
  # Inpatient Prospective Payment System Provider Summary for the Top 100 Diagnosis-Related Groups - FY2011, and Inpatient Charge Data FY 2011.
  # AWS modified the data to introduce a couple of erroneous records at the tail end of the file
  data_source = "s3://awsglue-datasets/examples/medicare/Medicare_Hospital_Provider.csv"

  # lakeformation tags and resources
  lf_tags = {
    module = ["Orders", "Sales", "Customers"]
  }
  resources = {
    database = {
      name = aws_glue_catalog_database.glue.name
      # name = aws_athena_database.athena.name
      tags = local.lf_tags
    }
  }
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
                "aws:sourceVpce" = var.vpce
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


### security/policy
module "roles" {
  for_each = { for role in [
    {
      name        = "datalake-admin"
      tags        = { desc = "data lake admin" }
      policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess", ]
    },
    {
      name        = "datalake-ops"
      tags        = { desc = "data lake operator" }
      policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess", ]
    },
  ] : role.name => role }
  source      = "Young-ook/passport/aws//modules/iam-role"
  version     = "0.0.9"
  name        = each.key
  tags        = lookup(each.value, "tags", {})
  policy_arns = lookup(each.value, "policy_arns")
}

resource "aws_lakeformation_data_lake_settings" "lf" {
  admins = [module.roles["datalake-admin"].role.arn]
}

resource "aws_lakeformation_resource" "lf" {
  arn = module.s3.bucket.arn
}

resource "aws_lakeformation_permissions" "lf" {
  principal                     = module.roles["datalake-ops"].role.arn
  permissions                   = ["ALL"]
  permissions_with_grant_option = ["ALL"]
  table {
    database_name = aws_glue_catalog_database.glue.name
    name          = aws_glue_catalog_table.glue.name
  }
}

### database
resource "aws_athena_database" "athena" {
  name          = "hello"
  bucket        = module.s3.bucket.bucket
  force_destroy = true
}

resource "aws_glue_catalog_database" "glue" {
  name         = "payments"
  description  = "Glue Catalog database for the data located in ${local.data_source}"
  location_uri = local.data_source
}

resource "aws_glue_catalog_table" "glue" {
  name          = "medicare"
  description   = "Test Glue Catalog table"
  database_name = aws_glue_catalog_database.glue.name
}

### output variables
output "s3" {
  description = "Amazon S3 bucket"
  value       = module.s3
}
