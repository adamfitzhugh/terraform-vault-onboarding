# Terraform Vault Onboarding

> **Disclaimer:** This project is provided for demonstration and learning purposes only. It is not intended for production use without proper security review, hardening, and customization for your specific environment.

This directory contains Terraform configurations for onboarding tenants onto a self-managed Vault Enterprise cluster. It provides automated namespace provisioning, per-tenant pipeline identity, and authentication setup for multi-tenant Vault environments.

## Directory Structure

```
terraform-vault-onboarding/
├── namespace-root/         # Root namespace configuration
├── namespace-vending/      # Automated namespace provisioning
├── namespace-tn001/         # Tenant 1 namespace
├── namespace-tn002/         # Tenant 2 namespace
├── namespace-tn003/         # Tenant 3 namespace
├── modules/
│   ├── namespace/          # HCP Vault namespace creation module
│   ├── gha/                # GitHub Actions OIDC identity + GitHub Environment module
│   └── kv-engine/          # KV secrets engine module
├── policies/               # Vault policy HCL files
├── docs/                   # Documentation
└── Taskfile.yml            # Task automation configuration
```

### Monorepo Structure

This project uses a monorepo structure for simplification and ease of demonstration. All components (namespace-root, namespace-vending, and tenant namespaces) are contained in a single repository.

> **Production Recommendation:** For production deployments, it is recommended to separate `namespace-vending`, individual tenant namespaces (`namespace-tn001`, `namespace-tn002`, etc.), and the `modules/` directory into their own repositories. This separation provides:
> - **Improved isolation**: Tenant teams can manage their own repositories with appropriate access controls
> - **Independent CI/CD**: Each tenant can have separate pipelines and deployment schedules
> - **Better security boundaries**: Reduces the risk of accidental cross-tenant modifications
> - **Scalability**: As the number of tenants grows, separate repositories prevent a single monorepo from becoming unwieldy
> - **Module versioning**: Separate module repositories enable proper semantic versioning and controlled rollout of changes
> - **Reusability**: Modules can be published to a private Terraform registry and shared across multiple projects

> **Architecture & Design:** See [Solution Design Documentation](./docs/solution-design.md) for detailed architecture, authentication flows, and design decisions.

## Prerequisites

- Terraform >= 1.14.0
- A Vault Enterprise cluster, already running and reachable (namespaces are an Enterprise feature)
- An S3 bucket and AWS credentials for Terraform state
- A GitHub repository with Actions enabled, and permission to create Environments
- [Task](https://taskfile.dev/) (optional, for automation)

The cluster is **not** provisioned by this repository. There is no bootstrap step:
`VAULT_ADDR` / `VAULT_TOKEN` come from your environment (see `.env.example`).

## Workflow

The configurations should be applied in the following order:

1. **Namespace Root**: Configures the Vault `admin` namespace with OIDC authentication and identity groups.
2. **Namespace Vending**: Creates child namespaces for tenants, together with the GitHub Actions identity (JWT role + GitHub Environment) each tenant pipeline uses.
3. **Tenant Namespaces**: Individual tenant namespaces can be customized independently.

## Configuration

Copy the example variables file for the vending layer and fill it in:

```bash
cp ./namespace-vending/terraform.tfvars.example ./namespace-vending/terraform.tfvars
```

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `github_organization` | GitHub organization name | `"example-org"` | Yes |
| `github_repository` | Repository name | `"terraform-vault-onboarding"` | Yes |
| `bound_audience` | Audience the Actions OIDC token must carry, and which the Vault role requires | `"vault.internal"` | Yes |
| `vault_auth_path` | Mount path for the JWT auth backend | `"gha"` | Yes |
| `vault_auth_role` | Vault JWT role name | `"tfc-namespace-admin"` | No (default) |
| `vault_namespace` | Parent Vault namespace | `"admin"` | No (default) |

State is stored in S3 using a partial backend configuration, supplied at init:

```bash
terraform -chdir=namespace-vending init \
  -backend-config="bucket=<state-bucket>" \
  -backend-config="key=vending/terraform.tfstate" \
  -backend-config="region=<region>" \
  -backend-config="use_lockfile=true"
```

## Usage

The project uses a vending pattern where namespaces and workspaces are centrally managed, while tenants configure their own resources (like KV engines) within their assigned namespace.

### Namespace Vending

Defined in `namespace-vending/tn001.tf`, this creates the Vault namespace and the corresponding GitHub Actions identity.

```hcl
module "tn001_namespace" {
  source           = "../modules/namespace"
  namespace        = "tn001"
  description      = "Tenant 1 namespace"
  admin_group_name = "vault-tn001-admin"
}

module "tn001_runner" {
  source = "../modules/gha"

  github_organization = var.github_organization
  github_repository   = var.github_repository

  tenant         = module.tn001_namespace.namespace
  bound_audience = var.bound_audience

  vault_auth_path = var.vault_auth_path
  vault_auth_role = var.vault_auth_role
  vault_namespace = module.tn001_namespace.namespace
}
```

### Tenant Configuration

Defined in `namespace-tn001/main.tf`, tenants manage their own secrets engines and other resources.

```hcl
module "kv_engine" {
  source      = "../modules/kv-engine"
  path        = "shared/"
  description = "KV v2 secrets"
}
```

## Authentication

### GitHub Actions to Vault (machine plane)

Uses JWT authentication against the GitHub Actions OIDC issuer
(`https://token.actions.githubusercontent.com`). Each tenant's role binds the
`repository`, `environment` and `event_name` claims individually. Because a monorepo
gives every tenant an identical `repository` claim, **`environment` is the tenant
boundary**: one GitHub Environment per tenant, declared by the workflow job. A job that
declares no environment emits no `environment` claim, and Vault treats an absent bound
claim as a failure — so it fails closed.

`event_name` is bound to `push` because `pull_request` runs also mint valid tokens.

### Okta to Vault (human plane)

OIDC authentication is configured in the root Vault namespace. Users authenticate via the
IdP and receive tokens based on their group membership.

## Adding a New Tenant

1. Create a namespace definition in `namespace-vending/tn{XXX}.tf`
2. Create a dedicated directory `namespace-tn{XXX}/`
3. Add the required files:
  - `main.tf`
  - `providers.tf`
  - `variables.tf`
4. Apply namespace-vending first, then the tenant configuration
5. Reference the tenant's GitHub Environment from its workflow job (`environment: tn{XXX}`) — without this the OIDC token carries no `environment` claim and Vault login fails

## Policies

Vault policy HCL files are stored in the `policies/` directory:

| Policy | Description |
|--------|-------------|
| `tfc_admin_policy.hcl` | Full admin access for pipeline identities |
| `tfc_namespace_admin_policy.hcl` | Namespace-scoped admin access |
| `namespace_admin_policy.hcl` | Namespace administrator permissions |
| `vault_admin_policy.hcl` | Vault Admin ACL policy |

## Development

### Linting & Formatting

The project uses `pre-commit` and `tflint` for code quality.

- **Pre-commit**: Runs automatically on commit if installed (`pre-commit install`). Can be run manually via `task lint`.
- **Formatting**: Enforced via `terraform fmt`.
- **Linting**: Uses `tflint` with recursive checks across all modules.

## Additional Resources

- [Vault Provider Documentation](https://registry.terraform.io/providers/hashicorp/vault/latest/docs)
- [GitHub Provider Documentation](https://registry.terraform.io/providers/integrations/github/latest/docs)
- [Okta Provider Documentation](https://registry.terraform.io/providers/okta/okta/latest/docs)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
