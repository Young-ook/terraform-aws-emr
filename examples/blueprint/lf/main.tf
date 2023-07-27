variable "s3_arn" {
  type = string
}

### data lake
module "datalake-admin" {
  source           = "Young-ook/passport/aws//modules/iam-role"
  version          = "0.0.7"
  name             = "datalake-admin"
  tags             = { desc = "data lake admin" }
  session_duration = "7200"
  policy_arns      = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

resource "aws_lakeformation_data_lake_settings" "lf" {
  admins = [module.datalake-admin.role.arn]
}

resource "aws_lakeformation_resource" "lf" {
  arn = var.s3_arn
}
