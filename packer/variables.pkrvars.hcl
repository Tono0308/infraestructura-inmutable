# Valores por defecto para builds manuales:
#   packer build -var-file=variables.pkrvars.hcl aws-ubuntu.pkr.hcl
# Sube app_version cada vez que cambies la app: queda en el tag Version de la AMI
# y se muestra en la página (útil para ver el rolling update en la demo).
region      = "us-east-1"
app_version = "1.0.0"
