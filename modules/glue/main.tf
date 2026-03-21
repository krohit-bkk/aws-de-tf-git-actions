# Glue - Connection name details for VPC & RDS MySQL
locals {
  rds_connection_name = "${var.project_name}-conn-rds-mysql"
  vpc_connection_name = "${var.project_name}-conn-vpc"

  glue_databases = {
    "${replace(var.project_name, "-", "_")}_db_on_s3"  = "Glue catalog database for ${var.project_name} based on files from S3"
    "${replace(var.project_name, "-", "_")}_db_on_rds" = "Glue catalog database for ${var.project_name} based on tables from RDS"
  }
}

# Upload Glue scripts to S3
resource "aws_s3_object" "glue_scripts" {
  for_each = {
    "merge_customers_accounts" = "modules/glue/scripts/merge_customers_accounts.py"
    "push_to_rds"              = "modules/glue/scripts/push_to_rds.py"
  }

  bucket = var.s3_bucket_name
  key    = "scripts/glue/${each.key}.py"
  source = each.value
  etag   = filemd5(each.value)

  tags = {
    Name    = "${var.project_name}-glue-script-${each.key}"
    project = var.project_name
  }
}

# Glue Catalog Databases
resource "aws_glue_catalog_database" "databases" {
  for_each    = local.glue_databases
  name        = each.key
  description = each.value
}

# Glue VPC Connection
resource "aws_glue_connection" "vpc_connection" {
  name            = local.vpc_connection_name
  description     = "VPC connection for ${var.project_name} Glue jobs"
  connection_type = "NETWORK"

  physical_connection_requirements {
    availability_zone      = "${var.aws_region}c"
    subnet_id              = var.subnet_ids["subnet_2"]
    security_group_id_list = [var.security_group_id]
  }

  tags = {
    Name    = "${var.project_name}-conn-vpc"
    project = var.project_name
  }
}

# Glue RDS MySQL Connection
resource "aws_glue_connection" "rds_connection" {
  name            = local.rds_connection_name
  description     = "Connects Glue with RDS MySQL Instance for ${var.project_name}"
  connection_type = "JDBC"

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:mysql://${var.rds_endpoint}/${var.rds_db_name}"
    SECRET_ID           = var.rds_secret_arn
  }

  physical_connection_requirements {
    availability_zone      = "${var.aws_region}c"
    subnet_id              = var.subnet_ids["subnet_2"]
    security_group_id_list = [var.security_group_id]
  }

  tags = {
    Name    = local.rds_connection_name
    project = var.project_name
  }
}

# Glue Jobs
resource "aws_glue_job" "jobs" {
  for_each = {
    "${var.project_name}-01-merge-customers-accounts" = {
      script      = "s3://${var.s3_bucket_name}/scripts/glue/merge_customers_accounts.py"
      connections = [local.vpc_connection_name]
      description = "Merges customers and accounts data from S3"
    }
    "${var.project_name}-02-push-to-rds" = {
      script      = "s3://${var.s3_bucket_name}/scripts/glue/push_to_rds.py"
      connections = [local.vpc_connection_name, local.rds_connection_name]
      description = "Pushes harmonized data to RDS MySQL"
    }
  }

  name         = each.key
  description  = each.value.description
  role_arn     = var.glue_role_arn
  glue_version = "4.0"

  command {
    name            = "glueetl"
    script_location = each.value.script
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--continuous-log-logGroup"          = var.glue_jobs_log_group_name
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "true"
    "--S3_BUCKET_NAME"                   = var.s3_bucket_name
    "--RDS_CONNECTION_NAME"              = local.rds_connection_name
  }

  connections = each.value.connections

  number_of_workers = 2
  worker_type       = "G.1X"

  tags = {
    Name    = each.key
    project = var.project_name
  }

  depends_on = [aws_s3_object.glue_scripts]
}

# Glue Crawler 1 - crawl over S3
resource "aws_glue_crawler" "s3_crawler" {
  name          = "${var.project_name}-03-glue-crawler-s3-01"
  description   = "Glue crawler for ${var.project_name} based on files from S3"
  role          = var.glue_role_arn
  database_name = "${replace(var.project_name, "-", "_")}_db_on_s3"
  schedule      = null

  s3_target {
    path = "s3://${var.s3_bucket_name}/data/harmonized/"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = {
        AddOrUpdateBehavior = "InheritFromTable"
      }
    }
  })

  tags = {
    Name    = "${var.project_name}-03-glue-crawler-s3-01"
    project = var.project_name
  }

  depends_on = [aws_glue_catalog_database.databases]
}

# Glue Crawler 2 - crawl over RDS
resource "aws_glue_crawler" "rds_crawler" {
  name          = "${var.project_name}-04-glue-crawler-rds-01"
  description   = "Glue crawler for ${var.project_name} based on tables from RDS"
  role          = var.glue_role_arn
  database_name = "${replace(var.project_name, "-", "_")}_db_on_rds"
  schedule      = null

  jdbc_target {
    connection_name = local.rds_connection_name
    path            = "${var.rds_db_name}/%"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = {
        AddOrUpdateBehavior = "InheritFromTable"
      }
    }
  })

  tags = {
    Name    = "${var.project_name}-04-glue-crawler-rds-01"
    project = var.project_name
  }

  depends_on = [
    aws_glue_catalog_database.databases,
    aws_glue_connection.rds_connection
  ]
}