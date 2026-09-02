resource "vault_namespace" "default" {
  path = var.namespace
  custom_metadata = {
    created-by  = "Terraform onboarding provisioner"
    description = var.description
  }
}

resource "vault_quota_rate_limit" "namespace" {
  count    = var.enable_quotas ? 1 : 0
  name     = vault_namespace.default.path
  path     = "${var.namespace}/"
  interval = 30
  rate     = var.quota_rate_limit
}

resource "vault_quota_lease_count" "namespace" {
  count      = var.enable_quotas ? 1 : 0
  name       = vault_namespace.default.path
  path       = "${var.namespace}/"
  max_leases = var.quota_lease_count
}

# Delegate namespace group admin
# https://developer.hashicorp.com/vault/tutorials/enterprise/namespaces
#
# There was a `data "okta_group"` here, queried by var.admin_group_name and read
# back only for `.name` - the same string. It supplied no data; its only effect
# was to fail the plan when the group did not exist in Okta. The AWS provider has
# no equivalent lookup for a Cognito group by name, so that assertion is gone and
# the check block below stands in its place.
#
# Without it, a misspelled group name is not a plan-time error: Vault matches
# aliases by exact name, finds none, and the user authenticates into no groups
# holding only the default policy. It fails closed, but presents as a permissions
# problem rather than a naming one.
data "vault_auth_backend" "oidc" {
  path = var.oidc_auth_path
}

check "group_names" {
  assert {
    condition = alltrue(concat(
      [can(regex(local.group_name_pattern, var.admin_group_name))],
      [for k, v in var.rbac_delegation : can(regex(local.group_name_pattern, v.group_name))]
    ))
    error_message = "Group names must match ${local.group_name_pattern}. Adjust the pattern to your convention - this is the only remaining guard against a typo that would otherwise surface as a permissions failure at login."
  }
}

resource "vault_identity_group" "namespace_admin_external" {
  name = "${var.admin_group_name}-external"
  type = "external"
}

resource "vault_identity_group_alias" "namespace_admin_external" {
  name           = var.admin_group_name
  mount_accessor = data.vault_auth_backend.oidc.accessor
  canonical_id   = vault_identity_group.namespace_admin_external.id
}

resource "vault_policy" "namespace_admin" {
  namespace = vault_namespace.default.path
  name      = "namespace-admin"
  policy    = file("${path.module}/../../policies/namespace_admin_policy.hcl")
}

resource "vault_identity_group" "namespace_admin_internal" {
  namespace        = vault_namespace.default.path
  name             = var.admin_group_name
  member_group_ids = concat([vault_identity_group.namespace_admin_external.id], var.additional_admin_group_ids)
  policies         = [vault_policy.namespace_admin.name]
}

# RBAC for the namespace
resource "vault_identity_group" "rbac_external" {
  for_each = var.rbac_delegation
  name     = "${each.value.group_name}-external"
  type     = "external"
  policies = ["default"]
}

resource "vault_identity_group_alias" "rbac_external" {
  for_each       = var.rbac_delegation
  name           = each.value.group_name
  mount_accessor = data.vault_auth_backend.oidc.accessor
  canonical_id   = vault_identity_group.rbac_external[each.key].id
}

resource "vault_policy" "rbac" {
  for_each = { for p in local.rbac_policies : p.name => p }

  namespace = vault_namespace.default.path
  name      = each.value.name
  policy    = each.value.policy
}

resource "vault_identity_group" "rbac_internal" {
  for_each         = var.rbac_delegation
  namespace        = vault_namespace.default.path
  name             = each.value.group_name
  member_group_ids = [vault_identity_group.rbac_external[each.key].id]
  policies = [
    for policy_key in keys(each.value.policies) :
    vault_policy.rbac["${each.key}-${policy_key}"].name
  ]
}
