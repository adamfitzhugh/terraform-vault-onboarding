variable "github_organization" {
  type        = string
  description = "Name of the GitHub organization."
}

variable "github_repository" {
  type        = string
  description = "Name of the GitHub repository."
}

variable "tenant" {
  type        = string
  description = "Tenant name. Used as the Vault namespace, the GitHub Environment name, and the value of the `environment` bound claim. Single source of truth - do not hardcode it separately anywhere."
}

variable "bound_audience" {
  type        = string
  description = "Audience the OIDC token must carry. Deliberately has no default: leaving bound_audiences unset disables audience validation entirely."
}

variable "vault_auth_path" {
  type        = string
  description = "Mount path where JWT Auth will be configured"
}

variable "vault_auth_role" {
  type        = string
  description = "Vault role name"
}

variable "vault_namespace" {
  type        = string
  description = "Vault namespace where resources (JWT backend, roles) will be created. If null, uses the provider's default namespace."
  default     = null
}

variable "vault_policy_name" {
  type        = string
  description = "Vault policy name"
  default     = "tfc-namespace-admin"
}

variable "token_ttl" {
  type        = string
  description = "Default lease TTL for Vault tokens"
  default     = 300 # 5 minutes
}

variable "token_max_ttl" {
  type        = string
  description = "Maximum lease TTL for Vault tokens"
  default     = 600 # 10 minutes
}

variable "token_type" {
  type        = string
  description = "Token type for the auth mount tune block"
  default     = "service"
}

variable "vault_token_type" {
  type        = string
  description = "Token type for Vault tokens issued by the role"
  default     = "service"
}

variable "vault_default_lease_ttl" {
  type        = string
  description = "Default lease TTL for the auth mount"
  default     = "10m"
}

variable "vault_max_lease_ttl" {
  type        = string
  description = "Maximum lease TTL for the auth mount"
  default     = "30m"
}
