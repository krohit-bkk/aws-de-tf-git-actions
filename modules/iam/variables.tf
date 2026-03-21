variable "project_name" {
  description = "Project identifier"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name used by Lambda and Glue"
  type        = string
  # value should be globally unique, flowing from project root directory variables.tf and controled by terraform.tfvars
}