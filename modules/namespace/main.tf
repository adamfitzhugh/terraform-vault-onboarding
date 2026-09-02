locals {
  rbac_policies = flatten([
    for delegation_key, delegation in var.rbac_delegation : [
      for policy_key, policy_hcl in delegation.policies : {
        group  = delegation_key
        name   = "${delegation_key}-${policy_key}"
        policy = policy_hcl
      }
    ]
  ])
}

locals {
  # The naming convention that replaces the deleted Okta existence check.
  # Group names must exist in Cognito with exactly this spelling.
  group_name_pattern = "^vault-[a-z0-9-]+$"
}
