terraform {
  backend "s3" {
    bucket       = "sir-app-terraform-state"
    key          = "prod/terraform.tfstate" # Path to the state file in the S3 bucket, isolated from dev
    region       = "eu-central-1"
    use_lockfile = true
  }
}