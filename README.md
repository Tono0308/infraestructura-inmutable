# infraestructura-inmutable
# Proyecto 10: GitOps e Infraestructura Inmutable

**Packer + Terraform + GitHub Actions en AWS**

---

## Descripción

Este proyecto implementa, de punta a punta, un modelo de **infraestructura inmutable** gestionado bajo el paradigma **GitOps** sobre **Amazon Web Services (AWS)**.

En lugar de administrar servidores que se actualizan "en caliente", cada cambio de aplicación o configuración genera una **nueva imagen de servidor (AMI)**, la cual es probada automáticamente y desplegada reemplazando por completo las instancias anteriores, **sin downtime**.

Todo el ciclo de vida —construcción de la imagen, despliegue de infraestructura y verificación de que AWS refleja exactamente lo definido en Git— está automatizado mediante **GitHub Actions**, de modo que ningún cambio en producción ocurra por fuera del control de versiones.

| Campo | Valor |
|---|---|
| **Plataforma Cloud** | Amazon Web Services (AWS) |
| **Nivel de dificultad** | Avanzado |
| **Duración estimada** | 8 semanas |
| **Trabajo en equipo** | Equipo de 4 estudiantes |
| **Paradigma** | Infraestructura Inmutable + GitOps |

---

## Integrantes

- Keren Saray Subiroz Galvan
- Mariana Oliver Palis
- Juan J. Martínez
- Gabriel Antonio González Puello

---

## Objetivos de Aprendizaje

- Entender y aplicar el paradigma de **infraestructura inmutable** frente al modelo mutable tradicional.
- Usar **HashiCorp Packer** para construir **AMIs doradas (Golden AMIs)** de forma automatizada.
- Integrar **Ansible** como provisioner dentro de un build de Packer.
- Implementar **Instance Refresh** en Auto Scaling Groups para lograr rolling updates sin downtime.
- Aplicar los principios de **GitOps**: Git como única fuente de verdad y reconciliación automatizada.
- Usar **AWS Systems Manager Session Manager** para acceso administrativo seguro, sin SSH ni bastion host.
- Implementar **pruebas automatizadas** de la AMI con Goss o InSpec antes de aprobarla como "golden".

---

## Arquitectura Propuesta

El siguiente diagrama resume la solución: desde el push a Git, pasando por la construcción y validación de la AMI, hasta el despliegue en AWS y el monitoreo continuo, incluyendo la detección de drift como proceso paralelo.

┌─────────────────────────────────────────────────────────────────────┐
│ REPOSITORIO GIT │
│ (fuente única de verdad) │
└──────────────────────────────┬──────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────────────┐
│ GITHUB ACTIONS - GitOps │
│ ┌──────────────┐ ┌──────────────┐ ┌────────────────────┐ │
│ │ ami-build │ │ infra-deploy │ │ instance-refresh │ │
│ │ build, test │ │ plan→apply │ │ rolling update │ │
│ └──────┬───────┘ └──────┬───────┘ └─────────┬──────────┘ │
└─────────┼─────────────────┼────────────────────┼────────────────────┘
│ │ │
▼ ▼ ▼
┌─────────────────────────────────────────────────────────────────────┐
│ INFRAESTRUCTURA INMUTABLE │
│ (cada cambio = nueva AMI = reemplazo completo) │
└──────────────────────────────┬──────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────────────┐
│ AMI Dorada → SSM Parameter Store → Launch Template → ASG │
│ (Goss/InSpec) (guarda AMI ID) (usa AMI vigente) │
└──────────────────────────────┬──────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────────────┐
│ VPC - INFRAESTRUCTURA EN AWS │
│ ┌──────┐ ┌──────────────────────────────────────────────┐ │
│ │ ALB │───▶│ Auto Scaling Group (EC2 x3) │ │
│ └──────┘ └──────────────────────────────────────────────┘ │
│ │ │ │
│ ▼ ▼ │
│ ┌──────────┐ ┌──────────────┐ ┌──────────────┐ │
│ │ IAM Role │ │ CloudWatch │──▶│ SNS Alert │ │
│ │ SSM only │ │ Dashboard │ │ unhealthy>0 │ │
│ └──────────┘ └──────────────┘ └──────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
▲
│
┌─────────────────────┐
│ DRIFT DETECTION │
│ (cron diario) │
│ terraform plan │
│ → Issue en GitHub │
└─────────────────────┘
