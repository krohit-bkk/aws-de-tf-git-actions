# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "log_groups" {
  for_each = toset([
    "/aws/${var.project_name}/lambda",
    "/aws/${var.project_name}/step-functions",
    "/aws/${var.project_name}/glue-jobs",
    "/aws/${var.project_name}/glue-crawler"
  ])

  name              = each.value
  retention_in_days = var.log_retention_days

  tags = {
    Name    = each.value
    project = var.project_name
  }
}