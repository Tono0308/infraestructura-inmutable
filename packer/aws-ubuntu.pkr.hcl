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

# Versión de goss fijada a propósito: "latest" apunta a v0.4.10, que no publica
# el binario goss-linux-amd64 (por eso la descarga daba 404).
# Versión de la aplicación que se hornea en la AMI (tag Version + página web)
variable "app_version" {
  type    = string
  default = "1.0.0"
}
variable "goss_version" {
  type    = string
  default = "v0.4.9"
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
    Version     = var.app_version
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
    # 1. Dependencias base del sistema (script)
  provisioner "shell" {
    script = "${path.root}/scripts/setup.sh"
  }

  # 2. Configuración con Ansible (app + nginx + CloudWatch Agent)
  provisioner "ansible" {
    playbook_file   = "${path.root}/../ansible/playbook.yml"
    user            = "ubuntu"
    extra_arguments = ["-e", "app_version=${var.app_version}"]

    # Si el log muestra errores de scp/sftp ("Failed to transfer file",
    # "Connection closed") con el OpenSSH 9.x del runner, usa esto en su lugar:
    # extra_arguments = ["-e", "app_version=${var.app_version}", "--scp-extra-args", "'-O'"]
  }

  provisioner "file" {
    source      = "${path.root}/goss/goss.yml"
    destination = "/tmp/goss.yml"
  }

  provisioner "shell" {
    execute_command = "sudo -E sh '{{ .Path }}'"
    inline = [
      "curl -L https://github.com/goss-org/goss/releases/download/${var.goss_version}/goss-linux-amd64 -o /usr/local/bin/goss",
      "chmod +rx /usr/local/bin/goss",
      "goss -g /tmp/goss.yml validate",
      "rm -f /tmp/goss.yml"
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