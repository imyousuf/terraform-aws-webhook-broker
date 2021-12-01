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

    external = {
      version = "~> 2.0.0"
    }

    null = {
      version = "~> 3.0.0"
    }

    template = {
      version = "~> 2.2.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.7.0"
    }

    helm = {
      version = "~> 2.0.2"
    }
  }

  #INJECT: Terraform Cloud Backend here in CI
}
