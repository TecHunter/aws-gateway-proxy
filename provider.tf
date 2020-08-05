provider "aws" {
  region = var.region
  profile = var.profile
}

provider "aws" {
  # us-east-1 instance
  region = "us-east-1"
  alias = "cert-provider"
}
