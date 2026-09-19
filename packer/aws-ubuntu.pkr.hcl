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

# Commit que dispara el build (lo pasa el pipeline con -var)
variable "git_commit" {
  type    = string
  default = "local-build"
}

# ID de la ejecución de GitHub Actions (lo pasa el pipeline con -var).
# Sirve para encontrar y terminar instancias huérfanas si un build se cancela.
variable "run_id" {
  type    = string
  default = "local"
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "mi-app-ubuntu-{{timestamp}}"
  instance_type = "t3.micro"
  region        = var.region
  ssh_username  = "ubuntu"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }

  # Tags que se le aplican a la AMI construida (Exigido en Sección 4.1)
  tags = {
    Name        = "Golden-AMI-Ubuntu"
    Version     = "1.0.0"
    BuildDate   = "{{timestamp}}"
    GitCommit   = var.git_commit
    Environment = "Production"
    ManagedBy   = "Packer"
  }

  # Tags de la instancia temporal del build (facilitan detectar instancias huérfanas)
  run_tags = {
    Name        = "Packer Builder"
    ManagedBy   = "Packer"
    PackerRunId = var.run_id
  }
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  # 1. Configuración con Ansible
  provisioner "ansible" {
    playbook_file = "${path.root}/../ansible/playbook.yml"
    user          = "ubuntu"

    # Si el log muestra errores de scp/sftp ("Failed to transfer file",
    # "Connection closed") con el OpenSSH 9.x del runner, descomenta esto:
    # extra_arguments = ["--scp-extra-args", "'-O'"]
  }

  # 2. Pruebas automatizadas con Goss
  provisioner "shell" {
    inline = [
      "curl -fsSL https://github.com/aelsabbahy/goss/releases/latest/download/goss-linux-amd64 -o /tmp/goss",
      "chmod +x /tmp/goss"
    ]
  }

  provisioner "file" {
    source      = "${path.root}/goss/goss.yml"
    destination = "/tmp/goss.yml"
  }

  provisioner "shell" {
    inline = [
      "/tmp/goss -g /tmp/goss.yml validate",
      "rm -f /tmp/goss /tmp/goss.yml"
    ]
  }

  # 3. Cleanup de la instancia antes de sellarla (Exigido en Sección 4.1)
  provisioner "shell" {
    inline = [
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*",
      "sudo rm -f /root/.ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys"
    ]
  }

  # 4. Genera manifest.json con el ID de la AMI (lo lee el workflow)
  post-processor "manifest" {
    output = "manifest.json"
  }
}