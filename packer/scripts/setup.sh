#!/usr/bin/env bash
# Primer provisioner: deja la instancia lista antes de correr Ansible.
set -euo pipefail

# Espera a que cloud-init termine (evita choques con apt en el primer arranque)
sudo cloud-init status --wait || true

sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-apt
