# Some preseed data
locals {
  prefix      = "${var.project_name}-${random_pet.nikname.id}"
  bucket_name = "${var.project_name}-relay-bucket"
}

data "aws_ami" "this_ami" {
  most_recent = true
  owners      = [var.ami_search[var.instance_type].ami_owner]
  filter {
    name   = "name"
    values = [var.ami_search[var.instance_type].ami_filter]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

/////////////////////////////
////////  Resources  ////////
/////////////////////////////

resource "random_pet" "nikname" {
  length = 1
}

resource "aws_key_pair" "this_kp" {
  key_name   = "${local.prefix}-kp"
  public_key = file(var.pub_key_path)

  tags = {
    Name      = "${local.prefix}-kp"
    Terraform = true
  }
}

resource "aws_iam_policy" "instance_policy" {
  name        = "${local.prefix}-instace-policy"
  path        = "/"
  description = "Bastion Host Policy"

  policy = templatefile("templates/node_policy.json", {
    bucket_name = local.bucket_name
  })

  tags = {
    Name      = "${local.prefix}-instace-policy"
    Terraform = true
  }
}

resource "aws_iam_role" "instance_role" {
  name = "${local.prefix}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "BastionAssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name      = "${local.prefix}-instance-role"
    Terraform = true
  }
}

resource "aws_iam_role_policy_attachment" "attach_instance" {
  role       = aws_iam_role.instance_role.name
  policy_arn = aws_iam_policy.instance_policy.arn
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${local.prefix}-instance-profile"
  role = aws_iam_role.instance_role.name
}

resource "aws_launch_template" "this_lt" {
  name     = "${local.prefix}-lt"
  image_id = data.aws_ami.this_ami.id
  key_name = aws_key_pair.this_kp.key_name

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.bastion_profile.name
  }

  monitoring {
    enabled = false
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.this_sg.id]
  }

  user_data = base64encode(templatefile("templates/userdata.sh", {
    instance_dns_name = var.instance_dns_name
    dns_zone          = var.dns_zone
    project           = var.project_name
    bkp_freq          = var.conf_bkp_freq
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name      = "${local.prefix}"
      Terraform = true
    }
  }
}

resource "aws_autoscaling_group" "this_asg" {
  name                      = "${local.prefix}-asg"
  vpc_zone_identifier       = aws_subnet.this_subnets.*.id
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  health_check_grace_period = 600
  health_check_type         = "EC2"

  launch_template {
    id      = aws_launch_template.this_lt.id
    version = "$Latest"
  }

  initial_lifecycle_hook {
    name                 = "${local.prefix}-launch-hook"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 300
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  }

  initial_lifecycle_hook {
    name                 = "${local.prefix}-terminate-hook"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 300
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
  }

  depends_on = [
    aws_cloudwatch_event_rule.autoscaling_evt_rule,
    aws_lambda_function.dns_handler_lambda,
    aws_lambda_permission.allow_cloudwatch,
    aws_iam_role.lambda_role
  ]
}
