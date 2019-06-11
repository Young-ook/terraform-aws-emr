# label.tf

resource "random_string" "this" {
  length  = 4
  upper   = false
  lower   = true
  number  = false
  special = false
}

### frigga naming rule
locals {
  name        = "${join("-", compact(list(var.name, var.stack, var.detail, local.slug)))}"
  slug        = "${var.slug == "" ? random_string.this.result : var.slug}"
  master_name = "${join("-", compact(list(local.name, "master")))}"
  slave_name  = "${join("-", compact(list(local.name, "slave")))}"
}
