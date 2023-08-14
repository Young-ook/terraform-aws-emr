### Amazon Redshift Cluster

### condition
locals {
  enabled          = (var.cluster != null ? ((length(var.cluster) > 0) ? true : false) : false)
  password         = lookup(var.cluster, "password", random_password.password.result)
  provisioned_mode = lookup(var.cluster, "mode", local.default_cluster.mode) == "provisioned" ? true : false
  serverless_mode  = lookup(var.cluster, "mode", local.default_cluster.mode) == "serverless" ? true : false
}

### security/password
resource "random_password" "password" {
  length           = 16
  min_numeric      = 1
  special          = true
  override_special = "~!#$%^*()_-+={}[],.;?:|"
}

### security/firewall
resource "aws_security_group" "dw" {
  for_each    = local.provisioned_mode || local.serverless_mode ? toset(["enabled"]) : []
  name        = local.name
  description = format("security group for %s", local.name)
  vpc_id      = var.vpc
  tags        = merge(local.default-tags, var.tags)

  ingress {
    from_port   = lookup(var.cluster, "port", local.default_cluster["port"])
    to_port     = lookup(var.cluster, "port", local.default_cluster["port"])
    protocol    = "tcp"
    cidr_blocks = var.cidrs
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

### network/subnets
resource "aws_redshift_subnet_group" "dw" {
  for_each   = local.provisioned_mode ? toset(["enabled"]) : []
  name       = local.name
  subnet_ids = var.subnets
  tags       = merge(local.default-tags, var.tags)
}

### database/parameters
resource "aws_redshift_parameter_group" "dw" {
  for_each = local.provisioned_mode ? toset(["enabled"]) : []
  name     = local.name
  tags     = merge(local.default-tags, var.tags)
  family   = lookup(var.cluster, "family", local.default_cluster.family)

  dynamic "parameter" {
    for_each = lookup(var.cluster, "cluster_parameters", local.default_cluster.cluster_parameters)
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

### datawarehouse/provisioned
resource "aws_redshift_cluster" "dw" {
  for_each                             = local.provisioned_mode ? toset(["enabled"]) : []
  cluster_identifier                   = local.name
  tags                                 = merge(local.default-tags, var.tags)
  cluster_parameter_group_name         = aws_redshift_parameter_group.dw["enabled"].name
  cluster_subnet_group_name            = aws_redshift_subnet_group.dw["enabled"].name
  cluster_version                      = lookup(var.cluster, "version", local.default_cluster.version)
  cluster_type                         = lookup(var.cluster, "number_of_nodes", local.default_cluster.number_of_nodes) > 1 ? "multi-node" : "single-node"
  node_type                            = lookup(var.cluster, "node_type", local.default_cluster.node_type)
  number_of_nodes                      = lookup(var.cluster, "number_of_nodes", local.default_cluster.number_of_nodes)
  port                                 = lookup(var.cluster, "port", local.default_cluster.port)
  allow_version_upgrade                = lookup(var.cluster, "allow_version_upgrade", local.default_cluster.allow_version_upgrade)
  apply_immediately                    = lookup(var.cluster, "apply_immediately", local.default_cluster.apply_immediately)
  skip_final_snapshot                  = lookup(var.cluster, "skip_final_snapshot", local.default_cluster.skip_final_snapshot)
  database_name                        = lookup(var.cluster, "database", local.default_cluster.database)
  encrypted                            = lookup(var.cluster, "encrypted", local.default_cluster.encrypted)
  availability_zone                    = lookup(var.cluster, "availability_zone", local.default_cluster.availability_zone)
  availability_zone_relocation_enabled = lookup(var.cluster, "availability_zone_relocation_enabled", local.default_cluster.availability_zone_relocation_enabled)
  enhanced_vpc_routing                 = lookup(var.cluster, "enhanced_vpc_routing", local.default_cluster.enhanced_vpc_routing)
  publicly_accessible                  = lookup(var.cluster, "publicly_accessible", local.default_cluster.publicly_accessible)
  elastic_ip                           = lookup(var.cluster, "elastic_ip", local.default_cluster.elastic_ip)
  vpc_security_group_ids               = coalescelist([aws_security_group.dw["enabled"].id], [])
  master_username                      = lookup(var.cluster, "user", local.default_cluster.user)
  master_password                      = local.password
  owner_account                        = lookup(var.cluster, "owner_account", local.default_cluster.owner_account)
  snapshot_cluster_identifier          = lookup(var.cluster, "snapshot_id", local.default_cluster.snapshot_id)
  automated_snapshot_retention_period  = lookup(var.cluster, "automated_snapshot_retention_period", local.default_cluster.automated_snapshot_retention_period)
  manual_snapshot_retention_period     = lookup(var.cluster, "manual_snapshot_retention_period", local.default_cluster.manual_snapshot_retention_period)

  dynamic "logging" {
    for_each = can(var.cluster.logging) ? [lookup(var.cluster, "logging")] : []
    content {
      enable               = true
      bucket_name          = try(logging.value.bucket_name, null)
      log_destination_type = try(logging.value.log_destination_type, null)
      log_exports          = try(logging.value.log_exports, null)
      s3_key_prefix        = try(logging.value.s3_key_prefix, null)
    }
  }

  dynamic "snapshot_copy" {
    for_each = can(var.cluster.snapshot_copy) ? [lookup(var.cluster, "snapshot_copy")] : []
    content {
      destination_region = snapshot_copy.value.destination_region
      grant_name         = try(snapshot_copy.value.grant_name, null)
      retention_period   = try(snapshot_copy.value.retention_period, null)
    }
  }

  lifecycle {
    ignore_changes        = [snapshot_identifier, master_password]
    create_before_destroy = true
  }
}

### datawarehouse/serverless
resource "awscc_redshiftserverless_namespace" "dw" {
  for_each                        = local.serverless_mode ? toset(["enabled"]) : []
  namespace_name                  = local.name
  tags                            = [for k, v in merge(local.default-tags, var.tags) : { key = k, value = v }]
  db_name                         = lookup(var.cluster, "database", local.default_cluster.database)
  admin_username                  = lookup(var.cluster, "user", local.default_cluster.user)
  admin_user_password             = local.password
  final_snapshot_retention_period = lookup(var.cluster, "manual_snapshot_retention_period", local.default_cluster.manual_snapshot_retention_period)

  lifecycle {
    ignore_changes        = [final_snapshot_name, admin_user_password]
    create_before_destroy = true
  }
}

resource "awscc_redshiftserverless_workgroup" "dw" {
  for_each             = local.serverless_mode ? toset(["enabled"]) : []
  depends_on           = [awscc_redshiftserverless_namespace.dw]
  workgroup_name       = local.name
  namespace_name       = awscc_redshiftserverless_namespace.dw["enabled"].namespace_name
  tags                 = [for k, v in merge(local.default-tags, var.tags) : { key = k, value = v }]
  enhanced_vpc_routing = lookup(var.cluster, "enhanced_vpc_routing", local.default_cluster.enhanced_vpc_routing)
  publicly_accessible  = lookup(var.cluster, "publicly_accessible", local.default_cluster.publicly_accessible)
  port                 = lookup(var.cluster, "port", local.default_cluster.port)
  security_group_ids   = coalescelist([aws_security_group.dw["enabled"].id], [])
  subnet_ids           = var.subnets
}
