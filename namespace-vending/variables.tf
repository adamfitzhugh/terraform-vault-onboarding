variable "github_organization" {
  type        = string
  description = "Name of the GitHub organization."
}

variable "github_repository" {
  type        = string
  description = "Name of the GitHub repository."
}

variable "bound_audience" {
  type        = string
  description = "Audience the GitHub Actions OIDC token must carry, and which the Vault JWT role requires. Must match the audience requested by the workflow."
}

variable "vault_auth_path" {
  type        = string
  description = "Mount path where JWT Auth will be configured"
}

variable "vault_auth_role" {
  type        = string
  description = "Vault role name"
  default     = "tfc-namespace-admin"
}

variable "vault_namespace" {
  type        = string
  description = "The parent Vault namespace"
  default     = "admin"
}

variable "vault_address" {
  type        = string
  description = "Vault API endpoint"
  default     = "https://vault.example.com"
}