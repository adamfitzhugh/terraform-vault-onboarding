# variable "github_organization" {
#   type        = string
#   description = "Name of the GitHub organization."
# }
#
# variable "github_repository" {
#   type        = string
#   description = "Name of the GitHub repository."
# }

# variable "tfc_organization" {
#   type        = string
#   description = "Name of the TFC organization."
# }
#
# variable "tfc_project" {
#   type        = string
#   description = "Name of the TFC project."
#   # default     = "default project"
# }
#
# variable "tfc_workspace" {
#   type        = string
#   description = "Name of the TFC worksapce."
#   default     = "terraform-vault-onboarding-baseline-configuration"
# }

variable "default_lease_ttl" {
  type        = string
  description = "Default lease TTL for Vault tokens"
  default     = "8h"
}

variable "max_lease_ttl" {
  type        = string
  description = "Maximum lease TTL for Vault tokens"
  default     = "24h"
}

variable "token_type" {
  type        = string
  description = "Token type for Vault tokens"
  default     = "default-service"
}

# variable "vault_auth_path" {
#   type        = string
#   description = "Mount path where JWT Auth will be configured"
# }

# variable "vault_address" {
#   type        = string
#   description = "Vault API endpoint"
# }
#
# variable "vault_address_tfc_agent" {
#   type        = string
#   description = "Vault API endpoint for TFC agent"
# }

# variable "vault_role_prefix" {
#   type        = string
#   description = "Vault role name"
#   default     = "tfc-admin"
# }

variable "aws_region" {
  type        = string
  description = "AWS region hosting the Cognito user pool."
}

variable "cognito_user_pool_id" {
  type        = string
  description = "Cognito user pool ID. Used to derive the OIDC issuer."
}

variable "cognito_client_id" {
  type        = string
  description = "Cognito app client ID. Also the expected `aud` claim - the app client must be configured to match."
}

variable "oidc_auth_path" {
  type        = string
  description = "Mount path for the OIDC auth backend."
  default     = "oidc"
}

variable "vault_address" {
  type        = string
  description = "Vault API endpoint. Used to construct allowed_redirect_uris, which the Cognito app client must also allow as callback URLs."
}

variable "mgmt_groups" {
  type        = list(string)
  description = "Cognito group names granted management access. These must exist in the pool with exactly these names: a mismatch is not detectable at plan time."
  default = [
    "vault-admin",
    "vault-user"
  ]
}
