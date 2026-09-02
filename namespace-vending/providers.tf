provider "github" {
  owner = var.github_organization
}

provider "vault" {
  #  skip_child_token = true
}
