packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "mi-app-ubuntu-{{timestamp}}"
  instance_type = "t3.micro"
  region        = var.region
  ssh_username  = "ubuntu"

  # Busca la AMI oficial más reciente de Ubuntu 22.04 proporcionada por Canonical
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "ansible" {
    playbook_file = "../ansible/playbook.yml"
    user          = "ubuntu"
    # Packer mapeará automáticamente la IP temporal al host "default" de Ansible
  }
}