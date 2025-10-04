provider "aws" {
  region = "eu-west-2"

  assume_role {
    role_arn     = "arn:aws:iam::${var.account_id}:role/GitHubAccessRole"
    session_name = "terraform"
  }

  default_tags {
    tags = {
      environment     = var.environment == "dev" ? "stable" : var.environment
      costcenter      = "mentor"
      Application     = "security"
      TFProject       = "infra-github-runner"
      service         = "security"
      confidentiality = "internal"
    }
  }
}

data "aws_canonical_user_id" "current_user" {
}

data "aws_availability_zones" "all" {
}

data "terraform_remote_state" "aws_account" {
  backend   = "s3"
  workspace = var.environment
  config = {
    bucket = "path-terraform-states"
    key    = "infra-aws-account-security.tfstate"
    region = "eu-west-2"
  }
}
