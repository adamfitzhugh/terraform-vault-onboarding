provider "aws" {
  region = var.aws_region
}

provider "vault" {
  #  skip_child_token = true
}
