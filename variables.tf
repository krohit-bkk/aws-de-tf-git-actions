variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Short project identifier used in resource names"
  type        = string
  default     = "tf-prj-01"
}

variable "account_id" {
  description = "Your AWS account ID"
  type        = string
  # no default — must be provided in terraform.tfvars
}

variable "s3_bucket_name" {
  description = "S3 bucket name used by Lambda and Glue"
  type        = string
}