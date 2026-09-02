# Replaces the deleted tfe_workspace. Under TFC, one resource provisioned both the
# runner's execution context and the identity it presented: the workspace name became
# the `sub` claim. Under Actions those are two systems. Terraform creates the Vault
# role that *expects* environment=<tenant>; this resource creates the GitHub
# Environment whose use *emits* that claim.
#
# Both halves are required, and a workflow job must also declare
# `environment: <tenant>` - creating the Environment is necessary but not
# sufficient. If either half is missing the tenant cannot authenticate, and the
# failure looks identical in both directions.
resource "github_repository_environment" "tenant" {
  repository  = var.github_repository
  environment = var.tenant
}
