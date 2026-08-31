terraform {
  backend "s3" {
    bucket       = "sir-app-terraform-state"
    key          = "dev/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}