### default variables

locals {
  default_studio = {
    # Specifies whether the Studio authenticates users using IAM or Amazon Web Services SSO.
    # Valid values are SSO or IAM.
    auth_mode = "IAM"
  }
}
