data "aws_route53_zone" "selected" {
  name         = var.dns_zone
  private_zone = false
}

data "archive_file" "lambda_function" {
  type             = "zip"
  source_file      = "${path.module}/lambda/manage_dns_record.py"
  output_file_mode = "0660"
  output_path      = "${path.module}/files/manage_dns_record.zip"
}

data "aws_iam_policy" "lambda_basic" {
  name = "AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${local.prefix}-lambda-policy"
  path        = "/"
  description = "DNS record handler Policy"

  policy = templatefile("templates/lambda_policy.json", {
    hosted_zone_id = data.aws_route53_zone.selected.id
    asg_arn        = aws_autoscaling_group.this_asg.arn
  })

  tags = {
    Name      = "${local.prefix}-lambda-policy"
    Terraform = true
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "${local.prefix}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "DNSHandlerAssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name      = "${local.prefix}-lambda-role"
    Terraform = true
  }

}

resource "aws_iam_role_policy_attachment" "attach_lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = data.aws_iam_policy.lambda_basic.arn
}

resource "aws_iam_role_policy_attachment" "attach_lambda_custom" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}


resource "aws_lambda_function" "dns_handler_lambda" {
  filename      = "files/manage_dns_record.zip"
  function_name = "${local.prefix}-dns-handler"
  description   = "Create/Modify/Remove DNS record on autoscaling events"
  role          = aws_iam_role.lambda_role.arn
  source_code_hash = data.archive_file.lambda_function.output_base64sha256
  handler = "manage_dns_record.lambda_handler"
  runtime = "python3.8"

  environment {
    variables = {
      HOSTED_ZONE_ID = data.aws_route53_zone.selected.id
      DNS_RECORD     = var.instance_dns_name
    }
  }

  depends_on = [
    data.archive_file.lambda_function,
  ]
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dns_handler_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.autoscaling_evt_rule.arn
}
