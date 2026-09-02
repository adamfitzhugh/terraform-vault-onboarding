terraform {
  # Partial configuration. Backend blocks cannot interpolate variables, so the
  # bucket/key/region are supplied at init time:
  #
  #   terraform init \
  #     -backend-config="bucket=<state-bucket>" \
  #     -backend-config="key=vending/terraform.tfstate" \
  #     -backend-config="region=<region>" \
  #     -backend-config="use_lockfile=true"
  #
  # The vending layer can create and destroy every tenant namespace. Its state
  # prefix must be readable only by the vending pipeline role, never by a tenant.
  backend "s3" {}
}
