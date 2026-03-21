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

variable "s3_bucket_name" {
  description = "S3 bucket name for data and scripts"
  type        = string
}

variable "glue_role_arn" {
  description = "ARN of the Glue IAM role"
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

variable "rds_endpoint" {
  description = "RDS instance endpoint"
  type        = string
}

variable "rds_db_name" {
  description = "RDS database name"
  type        = string
}

variable "rds_secret_arn" {
  description = "ARN of RDS credentials secret in Secrets Manager"
  type        = string
}

variable "glue_jobs_log_group_name" {
  description = "CloudWatch log group name for Glue jobs"
  type        = string
}