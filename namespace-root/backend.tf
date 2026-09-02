terraform {
  # Partial configuration. Backend blocks cannot interpolate variables, so the
  # bucket/key/region are supplied at init time:
  #
  #   terraform init \
  #     -backend-config="bucket=<state-bucket>" \
  #     -backend-config="key=namespace-root/terraform.tfstate" \
  #     -backend-config="region=<region>" \
  #     -backend-config="use_lockfile=true"
  #
  # This state holds the OIDC client secret. Restrict the prefix accordingly.
  backend "s3" {}
}
