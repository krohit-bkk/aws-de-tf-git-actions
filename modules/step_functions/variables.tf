variable "project_name" {
  description = "Project identifier"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "step_functions_role_arn" {
  description = "ARN of the Step Functions IAM role"
  type        = string
}

variable "step_functions_log_group_arn" {
  description = "ARN of the Step Functions CloudWatch log group"
  type        = string
}

variable "lambda_function_arns" {
  description = "Map of Lambda function ARNs"
  type        = map(string)
}

variable "glue_job_names" {
  description = "Map of Glue job names"
  type        = map(string)
}

variable "s3_crawler_name" {
  description = "Name of the S3 Glue crawler"
  type        = string
}

variable "rds_crawler_name" {
  description = "Name of the RDS Glue crawler"
  type        = string
}