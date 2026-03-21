variable "project_name" {
  description = "Project identifier"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
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

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "project_01"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "admin"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum storage for autoscaling - set to 0 to disable"
  type        = number
  default     = 0  # disabled for dev
}

variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "rds_monitoring_role_arn" {
  description = "ARN of the RDS enhanced monitoring IAM role"
  type        = string
}