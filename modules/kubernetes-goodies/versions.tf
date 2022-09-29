terraform {
  required_version = ">= 0.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.27.0"
    }

    local = {
      version = "~> 2.0.0"
    }

    template = {
      version = "~> 2.2.0"
    }

    kubernetes = {
      version = "~> 2.0.2"
    }

    helm = {
      version = "~> 2.7.0"
    }
  }
}
