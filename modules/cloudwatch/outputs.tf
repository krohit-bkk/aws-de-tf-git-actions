output "log_group_names" {
  description = "Map of all log group names"
  value       = { for k, v in aws_cloudwatch_log_group.log_groups : k => v.name }
}

output "lambda_log_group_name" {
  description = "Lambda log group name"
  value       = aws_cloudwatch_log_group.log_groups["/aws/${var.project_name}/lambda"].name
}

output "step_functions_log_group_arn" {
  description = "Step Functions log group ARN"
  value       = aws_cloudwatch_log_group.log_groups["/aws/${var.project_name}/step-functions"].arn
}

output "glue_jobs_log_group_name" {
  description = "Glue jobs log group name"
  value       = aws_cloudwatch_log_group.log_groups["/aws/${var.project_name}/glue-jobs"].name
}

