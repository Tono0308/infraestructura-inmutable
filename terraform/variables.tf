variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo para nombrar los recursos. El ASG queda como <project_name>-asg (lo usa instance-refresh.yml)."
  type        = string
  default     = "mi-app"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 4
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "ami_ssm_parameter_name" {
  description = "Parámetro de SSM donde ami-build.yml guarda el AMI ID vigente"
  type        = string
  default     = "/gitops/ami/latest_id"
}

variable "alert_email" {
  description = "Correo que recibe las alertas SNS. Vacío = se crea el topic sin suscripción."
  type        = string
  default     = ""
}
