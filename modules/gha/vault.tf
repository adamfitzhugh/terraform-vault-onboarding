resource "vault_policy" "namespace_admin" {
  count     = var.vault_namespace != null ? 1 : 0
  namespace = var.vault_namespace
  name      = var.vault_policy_name
  policy    = file("${path.module}/../../policies/tfc_namespace_admin_policy.hcl")
}

resource "vault_jwt_auth_backend" "actions" {
  count       = var.vault_namespace != null ? 1 : 0
  namespace   = var.vault_namespace
  type        = "jwt"
  path        = var.vault_auth_path
  description = "JWT auth backend for GitHub Actions"

  bound_issuer       = "https://token.actions.githubusercontent.com"
  oidc_discovery_url = "https://token.actions.githubusercontent.com"

  tune {
    default_lease_ttl = var.vault_default_lease_ttl
    max_lease_ttl     = var.vault_max_lease_ttl
    token_type        = var.token_type
  }
}

resource "vault_jwt_auth_backend_role" "namespace_admin" {
  namespace = var.vault_namespace
  backend   = var.vault_namespace != null ? vault_jwt_auth_backend.actions[0].path : var.vault_auth_path

  role_type      = "jwt"
  role_name      = var.vault_auth_role
  token_type     = var.vault_token_type
  token_policies = [var.vault_policy_name]
  token_ttl      = var.token_ttl
  token_max_ttl  = var.token_max_ttl

  # bound_audiences must be set explicitly. GitHub defaults `aud` to the repository
  # owner URL, not vault.workload.identity, and an unset bound_audiences disables
  # audience validation entirely rather than accepting a default.
  bound_audiences = [var.bound_audience]

  # Individual claims rather than a single `sub` glob. Each line is an independent
  # condition; every one must be present in the token AND equal. An absent claim is
  # a failure, not a skipped check - which is what makes `environment` a real
  # tenant boundary in a monorepo, where `repository` alone is identical for all
  # tenants.
  #
  # event_name is bound because pull_request runs also mint valid tokens. Without
  # this line, opening a PR is an authentication path.
  bound_claims = {
    repository  = "${var.github_organization}/${var.github_repository}"
    environment = var.tenant
    event_name  = "push"
  }

  # "string", not "glob". Upstream used glob only to wildcard run_phase:* in the TFC
  # sub claim. Leaving it as glob would make `*` significant in every bound value.
  bound_claims_type = "string"

  user_claim = "actor"
}
