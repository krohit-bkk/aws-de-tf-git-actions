output "glue_job_names" {
  description = "Map of Glue job names"
  value       = { for k, v in aws_glue_job.jobs : k => v.name }
}

output "s3_crawler_name" {
  description = "Name of the S3 Glue crawler"
  value       = aws_glue_crawler.s3_crawler.name
}

output "rds_crawler_name" {
  description = "Name of the RDS Glue crawler"
  value       = aws_glue_crawler.rds_crawler.name
}

output "vpc_connection_name" {
  description = "Name of the Glue VPC connection"
  value       = aws_glue_connection.vpc_connection.name
}

output "rds_connection_name" {
  description = "Name of the Glue RDS connection"
  value       = aws_glue_connection.rds_connection.name
}

output "glue_database_names" {
  description = "Map of Glue catalog database names"
  value       = { for k, v in aws_glue_catalog_database.databases : k => v.name }
}