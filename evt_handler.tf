resource "aws_cloudwatch_event_rule" "autoscaling_evt_rule" {
  name        = "${local.prefix}-autoscaling-rule"
  description = "Capture each autoscaling event"

  event_pattern = jsonencode({
    "source" : [
      "aws.autoscaling"
    ],
    "detail-type" : [
      "EC2 Instance-launch Lifecycle Action",
      "EC2 Instance-terminate Lifecycle Action"
    ]
  })

  tags = {
    Name      = "${local.prefix}-eventbridge-rule"
    Terraform = true
  }
}

resource "aws_cloudwatch_event_target" "dns_handler" {
  rule      = aws_cloudwatch_event_rule.autoscaling_evt_rule.name
  target_id = "${local.prefix}-InvokeDNSHandler"
  arn       = aws_lambda_function.dns_handler_lambda.arn
}