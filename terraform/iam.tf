data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name               = "${local.name}-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# Session Manager (acceso administrativo sin SSH ni bastion)
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Publicar métricas del CloudWatch Agent horneado en la AMI
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Leer únicamente el parámetro del AMI ID
data "aws_iam_policy_document" "read_ami_param" {
  statement {
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${var.ami_ssm_parameter_name}"]
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "read_ami_param" {
  name   = "read-ami-parameter"
  role   = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.read_ami_param.json
}

resource "aws_iam_instance_profile" "instance" {
  name = "${local.name}-instance-profile"
  role = aws_iam_role.instance.name
}
