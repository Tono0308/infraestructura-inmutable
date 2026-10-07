output "alb_dns_name" {
  description = "URL pública de la app"
  value       = "http://${aws_lb.app.dns_name}"
}

output "asg_name" {
  description = "Nombre del ASG (debe coincidir con instance-refresh.yml)"
  value       = aws_autoscaling_group.app.name
}

output "current_ami_id" {
  description = "AMI vigente según SSM Parameter Store"
  value       = data.aws_ssm_parameter.current_ami.value
  sensitive   = true
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}