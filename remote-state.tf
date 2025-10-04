terraform {
  backend "s3" {
    bucket       = "path-terraform-states"
    key          = "infra-github-runner.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }
}

