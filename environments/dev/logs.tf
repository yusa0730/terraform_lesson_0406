resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.env}/app"
  retention_in_days = 30
}
