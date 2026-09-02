data "aws_cognito_user_pool_client" "vault" {
  user_pool_id = var.cognito_user_pool_id
  client_id    = var.cognito_client_id
}

resource "vault_identity_group" "vault_user" {
  name              = "${local.mgmt_groups["vault-user"]}-external"
  type              = "external"
  external_policies = true
}

resource "vault_identity_group_alias" "vault_user" {
  name           = local.mgmt_groups["vault-user"]
  mount_accessor = vault_jwt_auth_backend.oidc.accessor
  canonical_id   = vault_identity_group.vault_user.id
}

resource "vault_identity_group" "vault_admin" {
  name              = "${local.mgmt_groups["vault-admin"]}-external"
  type              = "external"
  external_policies = true
}

resource "vault_identity_group_alias" "vault_admin" {
  name           = local.mgmt_groups["vault-admin"]
  mount_accessor = vault_jwt_auth_backend.oidc.accessor
  canonical_id   = vault_identity_group.vault_admin.id
}

resource "vault_identity_group_policies" "vault_admin" {
  group_id  = vault_identity_group.vault_admin.id
  exclusive = false
  policies = [
    resource.vault_policy.vault_admin.name,
    resource.vault_policy.vault_admin_namespace.name
  ]
}

resource "vault_jwt_auth_backend" "oidc" {
  description        = "Cognito OIDC Auth Method"
  path               = var.oidc_auth_path
  type               = "oidc"
  default_role       = "cognito-group"
  namespace_in_state = true

  bound_issuer       = local.cognito_issuer
  oidc_discovery_url = local.cognito_issuer
  oidc_client_id     = data.aws_cognito_user_pool_client.vault.id
  oidc_client_secret = data.aws_cognito_user_pool_client.vault.client_secret

  tune {
    default_lease_ttl  = var.default_lease_ttl
    listing_visibility = "unauth"
    max_lease_ttl      = var.max_lease_ttl
    token_type         = var.token_type
  }
}

resource "vault_jwt_auth_backend_role" "cognito_group" {
  backend   = vault_jwt_auth_backend.oidc.path
  role_type = vault_jwt_auth_backend.oidc.type
  role_name = "cognito-group"

  bound_audiences = [data.aws_cognito_user_pool_client.vault.id]
  user_claim      = "email"
  token_policies  = ["default"]

  # Cognito's claim name is literally colon-prefixed. It is a top-level claim,
  # so the plain string works - Vault's /nested/pointer syntax is not needed.
  groups_claim = "cognito:groups"

  # The Okta role requested a "groups" scope. Cognito defines no such scope and
  # requesting an undefined one fails the authorize call; cognito:groups is
  # emitted without being asked for. This must change, not merely shrink.
  oidc_scopes = ["profile", "email"]

  # Vault expects these; the Cognito app client must independently allow the
  # same URLs as callback URLs. Nothing enforces the agreement - a mismatch is
  # rejected at Cognito, before Vault is involved.
  allowed_redirect_uris = [
    "${var.vault_address}/ui/vault/auth/${var.oidc_auth_path}/oidc/callback",
    "http://localhost:8250/oidc/callback",
  ]

  # bound_claims_type deliberately omitted. The Okta role carried "glob" with no
  # bound_claims to apply to - inert, but the same trap disarmed in the machine
  # plane. Do not reintroduce it without bound_claims that need globbing.
}

resource "vault_policy" "vault_admin" {
  name   = "vault-admin"
  policy = file("./${path.module}/../policies/vault_admin_policy.hcl")
}

resource "vault_policy" "vault_admin_namespace" {
  name   = "vault-admin-namespace"
  policy = file("./${path.module}/../policies/vault_admin_namespace_policy.hcl")
}
