locals {
  cognito_issuer = "https://cognito-idp.${var.aws_region}.amazonaws.com/${var.cognito_user_pool_id}"

  # Previously these names round-tripped through data.okta_group, which returned
  # the name it was queried with. Its only real effect was to fail the plan when
  # a group did not exist. The AWS provider has no equivalent lookup for a
  # Cognito group by name, so that assertion is gone - see the check block below.
  mgmt_groups = { for g in var.mgmt_groups : g => g }
}

# Replaces the existence assertion that data.okta_group provided for free.
# Adjust the regex to your group naming convention: this is a convention
# decision, not a technical one.
check "mgmt_group_names" {
  assert {
    condition     = alltrue([for g in var.mgmt_groups : can(regex("^vault-[a-z0-9-]+$", g))])
    error_message = "Management group names must match ^vault-[a-z0-9-]+$. A name that does not exist in Cognito cannot be detected at plan time: the user will authenticate successfully into no groups, holding only the default policy."
  }
}

# resource "vault_quota_rate_limit" "global" {
#   name     = "global"
#   path     = ""
#   interval = 30
#   rate     = 300000
# }

# resource "vault_audit" "file" {
#   options = {
#     file_path = "/var/logs/vault_audit.log"
#   }
#   type = "file"
# }
