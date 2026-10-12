terraform {
  required_version = ">= 1.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket       = "gatekeeper-tfstate-843109108746"
    key          = "gatekeeper/main.tfstate"
    region       = "eu-west-3"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-west-3"
  default_tags {
    tags = {
      Project     = "gatekeeper"
      Owner       = "ishaan"
      Environment = "lab"
    }
  }
}
