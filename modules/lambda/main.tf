# Zip Lambda 1 - create_s3_folders
data "archive_file" "create_s3_folders_zip" {
  type        = "zip"
  source_dir  = "${path.module}/functions/create_s3_folders"
  output_path = "${path.module}/functions/create_s3_folders.zip"
}

# Zip Lambda 2 - ingest_files_to_s3
data "archive_file" "ingest_files_to_s3_zip" {
  type        = "zip"
  source_dir  = "${path.module}/functions/ingest_files_to_s3"
  output_path = "${path.module}/functions/ingest_files_to_s3.zip"
}

# Local variable to define Lambda configurations
locals {
  lambda_functions = {
    "001-create-ingestion-folders-on-s3" = {
      zip          = data.archive_file.create_s3_folders_zip.output_path
      source_hash  = data.archive_file.create_s3_folders_zip.output_base64sha256
      subnet_ids   = [var.subnet_ids["subnet_1"], var.subnet_ids["subnet_3"]]
      description  = "Creates ingestion folders in S3"
    }
    "002-ingest-files-to-s3" = {
      zip          = data.archive_file.ingest_files_to_s3_zip.output_path
      source_hash  = data.archive_file.ingest_files_to_s3_zip.output_base64sha256
      subnet_ids   = [var.subnet_ids["subnet_2"], var.subnet_ids["subnet_4"]]
      description  = "Ingests files from remote server to S3"
    }
  }
}

# Lambda Functions
resource "aws_lambda_function" "functions" {
  for_each = local.lambda_functions

  function_name    = "${var.project_name}-${each.key}"
  filename         = each.value.zip
  source_code_hash = each.value.source_hash
  role             = var.lambda_role_arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 120

  vpc_config {
    subnet_ids         = each.value.subnet_ids
    security_group_ids = [var.security_group_id]
  }

  environment {
    variables = {
      S3_BUCKET_NAME = var.s3_bucket_name
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = var.lambda_log_group_name
  }

  tags = {
    Name    = "${var.project_name}-${each.key}"
    project = var.project_name
  }
}