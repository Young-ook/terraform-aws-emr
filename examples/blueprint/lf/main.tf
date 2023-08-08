variable "s3_arn" {
  type = string
}

variable "s3_bucket" {
  type = string
}

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
  arn = var.s3_arn
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
  bucket        = var.s3_bucket
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
