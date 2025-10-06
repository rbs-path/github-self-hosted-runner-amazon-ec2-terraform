data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_iam_role" "github_runner" {
  name = "${var.name}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "github_runner" {
  name = "${var.name}-ec2-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:ListSecrets",
          "secretsmanager:DescribeSecret"
        ]
        Resource = data.aws_secretsmanager_secret_version.github_app.arn
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite"
        ]
        Resource = aws_efs_file_system.github_runner_work.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name}-github-actions-runner-role"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "arn:aws:kms:eu-west-2:830138816992:key/041268dc-8044-4479-a527-c836c8a81bc9"
      }
    ]
  })
}

# Add Session Manager permissions
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.github_runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "github_runner" {
  role       = aws_iam_role.github_runner.name
  policy_arn = aws_iam_policy.github_runner.arn
}

resource "aws_iam_instance_profile" "github_runner" {
  name = "${var.name}-ec2-profile"
  role = aws_iam_role.github_runner.name
}

resource "aws_security_group" "github_runner" {
  name        = "${var.name}-sg"
  description = "Security group for GitHub self-hosted runners"
  vpc_id      = data.terraform_remote_state.aws_account.outputs.hub_vpc_id

  tags = {
    Name              = "${var.name}-sg"
    cactus_exclusions = "public"
  }
}

resource "aws_security_group_rule" "github_runner_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.github_runner.id
  #checkov:skip=CKV_AWS_382: Ensure no security groups allow egress from 0.0.0.0:0 to port -1
  #Reason: The Amazon EC2 instances require this to download packages
  #Reason: The instances are sufficiently protected since they're in private subnet

}

resource "aws_launch_template" "github_runner" {
  name_prefix   = var.name
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.runner_instance_type

  vpc_security_group_ids = [aws_security_group.github_runner.id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.github_runner.name
  }

  user_data = base64encode(templatefile("${path.module}/scripts/user_data.sh", {
    secret_name              = data.aws_secretsmanager_secret.github_app.name
    region                   = "eu-west-2"
    github_organization      = var.github_organization
    app_id                   = var.app_id
    installation_id          = var.installation_id
    efs_dns_name             = aws_efs_file_system.github_runner_work.dns_name
    lifecycle_log_group_name = aws_cloudwatch_log_group.github_runner_lifecycle.name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name}"
    }
  }
}

resource "aws_autoscaling_group" "github_runner" {
  name                      = "${var.name}-asg"
  vpc_zone_identifier       = data.terraform_remote_state.aws_account.outputs.hub_vpc_private_subnet_ids
  target_group_arns         = []
  health_check_type         = "EC2"
  health_check_grace_period = 300

  min_size         = var.runner_min_size
  max_size         = var.runner_max_size
  desired_capacity = var.runner_desired_capacity

  launch_template {
    id      = aws_launch_template.github_runner.id
    version = aws_launch_template.github_runner.latest_version
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0
      skip_matching          = true
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-asg"
    propagate_at_launch = false
  }
}
