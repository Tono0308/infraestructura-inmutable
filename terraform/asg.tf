resource "aws_launch_template" "app" {
  name_prefix   = "${local.name}-lt-"
  instance_type = var.instance_type

  # La AMI se resuelve en cada lanzamiento desde SSM Parameter Store.
  # ami-build.yml actualiza el parámetro -> instance-refresh.yml reemplaza las instancias.
  image_id = "resolve:ssm:${var.ami_ssm_parameter_name}"

  vpc_security_group_ids = [aws_security_group.instances.id]
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.instance.name
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.name}-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${local.name}-asg"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Rolling update sin downtime (sección 4.2 de la propuesta)
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 120
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.name}-instance"
    propagate_at_launch = true
  }

  lifecycle {
    # El escalado manual/automático no debe verse como drift
    ignore_changes = [desired_capacity]
  }
}
