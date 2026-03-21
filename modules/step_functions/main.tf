# Step Functions State Machine Definition
locals {
  state_machine_definition = jsonencode({
    Comment       = "State machine for ${var.project_name} DE pipeline"
    QueryLanguage = "JSONata"
    StartAt       = "Invoke_Folder_Creation_on_S3"
    States = {
      Invoke_Folder_Creation_on_S3 = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Output   = "{% $states.result.Payload %}"
        Arguments = {
          FunctionName = "${var.lambda_function_arns["001-create-ingestion-folders-on-s3"]}:$LATEST"
          Payload      = "{% $states.input %}"
        }
        Retry = [
          {
            ErrorEquals = [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException",
              "Lambda.TooManyRequestsException"
            ]
            IntervalSeconds = 1
            MaxAttempts     = 3
            BackoffRate     = 2
            JitterStrategy  = "FULL"
          }
        ]
        Next = "Ingest_Files_to_S3"
      }

      Ingest_Files_to_S3 = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Output   = "{% $states.result.Payload %}"
        Arguments = {
          FunctionName = "${var.lambda_function_arns["002-ingest-files-to-s3"]}:$LATEST"
          Payload      = "{% $states.input %}"
        }
        Retry = [
          {
            ErrorEquals = [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException",
              "Lambda.TooManyRequestsException"
            ]
            IntervalSeconds = 1
            MaxAttempts     = 3
            BackoffRate     = 2
            JitterStrategy  = "FULL"
          }
        ]
        Next = "Trigger_Glue_ETL_1"
      }

      Trigger_Glue_ETL_1 = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Arguments = {
          JobName = var.glue_job_names["${var.project_name}-01-merge-customers-accounts"]
        }
        Next       = "Trigger_Glue_ETL_2"
      }

      Trigger_Glue_ETL_2 = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Arguments = {
          JobName = var.glue_job_names["${var.project_name}-02-push-to-rds"]
        }
        Next       = "Trigger_Crawlers"
      }

      Trigger_Crawlers = {
        Type = "Parallel"
        Branches = [
          {
            StartAt = "Trigger_Glue_Crawler_for_S3"
            States = {
              Trigger_Glue_Crawler_for_S3 = {
                Type     = "Task"
                Resource = "arn:aws:states:::aws-sdk:glue:startCrawler"
                Arguments = {
                  Name = var.s3_crawler_name
                }
                End = true
              }
            }
          },
          {
            StartAt = "Trigger_Glue_Crawler_for_RDS"
            States = {
              Trigger_Glue_Crawler_for_RDS = {
                Type     = "Task"
                Resource = "arn:aws:states:::aws-sdk:glue:startCrawler"
                Arguments = {
                  Name = var.rds_crawler_name
                }
                End = true
              }
            }
          }
        ]
        End = true
      }
    }
  })
}

# Step Functions State Machine
resource "aws_sfn_state_machine" "main" {
  name       = "${var.project_name}-step-function-01"
  role_arn   = var.step_functions_role_arn
  definition = local.state_machine_definition

  logging_configuration {
    level                  = "ALL"
    include_execution_data = true
    log_destination        = "${var.step_functions_log_group_arn}:*"
  }

  tags = {
    Name    = "${var.project_name}-step-function-01"
    project = var.project_name
  }
}