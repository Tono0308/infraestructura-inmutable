terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Estado remoto: obligatorio porque el runner de GitHub Actions es efímero.
  # El bucket se crea UNA vez a mano (ver guía) y su nombre debe ser único global.
  backend "s3" {
    bucket       = "mi-app-tfstate-200090082104"
    key          = "infraestructura-inmutable/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # bloqueo nativo en S3 (Terraform >= 1.10), sin DynamoDB
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
    }
  }
}
