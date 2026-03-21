variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project identifier"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "subnet_cidrs" {
  description = "CIDR blocks for the 4 subnets"
  type        = map(string)
  default     = {
    subnet_1 = "192.168.0.0/18"
    subnet_2 = "192.168.64.0/18"
    subnet_3 = "192.168.128.0/18"
    subnet_4 = "192.168.192.0/18"
  }
}

variable "availability_zones" {
  description = "AZs for subnets"
  type        = map(string)
  default     = {
    subnet_1 = "ap-south-1a"
    subnet_2 = "ap-south-1c"
    subnet_3 = "ap-south-1a"
    subnet_4 = "ap-south-1c"
  }
}