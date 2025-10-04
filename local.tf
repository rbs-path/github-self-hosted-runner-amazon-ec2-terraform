data "aws_caller_identity" "current" {}
locals {
  principal_root_arn                = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  principal_logs_arn                = "logs.eu-west-2.amazonaws.com"
  gh_runner_lifecycle_log_group_arn = "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/${var.name}/lifecycle"
  secret_arn                        = "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:${var.name}-credentials-v2"
  sns_topic_arn                     = "arn:aws:sns:eu-west-2:${data.aws_caller_identity.current.account_id}:${var.name}-lifecycle"
  asg_arn                           = "arn:aws:autoscaling:eu-west-2:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/${var.name}-asg"
  lambda_arn                        = "arn:aws:lambda:eu-west-2:${data.aws_caller_identity.current.account_id}:function:${var.name}-deregistration"
}
