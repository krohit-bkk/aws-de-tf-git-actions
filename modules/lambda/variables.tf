variable "project_name" {
  description = "Project identifier"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Map of subnet IDs"
  type        = map(string)
}

variable "security_group_id" {
  description = "Security group ID"
  type        = string
}

variable "lambda_log_group_name" {
  description = "CloudWatch log group name for Lambda"
  type        = string
}