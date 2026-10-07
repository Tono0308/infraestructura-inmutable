# Red: se usa la VPC por defecto para evitar costos de NAT Gateway.
# Las instancias reciben IP pública pero su Security Group solo acepta tráfico del ALB
# (no hay puerto 22 abierto; el acceso administrativo es por SSM Session Manager).
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Falla con un error claro si ami-build.yml todavía no ha creado el parámetro.
# Ejecuta primero el workflow "AMI Build & SSM Update".
data "aws_ssm_parameter" "current_ami" {
  name = var.ami_ssm_parameter_name
}

locals {
  name = var.project_name
}
