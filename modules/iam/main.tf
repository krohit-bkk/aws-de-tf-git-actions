# ##################################################
# IAM module to create roles and policies for Lambda
# ##################################################

# Trust policy for Lambda role
data "aws_iam_policy_document" "lambda_trust_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name               = "${var.project_name}-role-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json

  tags = {
    Name    = "${var.project_name}-role-lambda"
    project = var.project_name
  }
}

# Permission policy document for Lambda
data "aws_iam_policy_document" "lambda_policy_doc" {
  statement {
    sid    = "S3Access"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }

  statement {
    sid    = "VPCAccess"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Logging"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

# IAM Policy for Lambda
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.project_name}-policy-lambda-execution"
  description = "Policy for Lambda to access S3, VPC and CloudWatch"
  policy      = data.aws_iam_policy_document.lambda_policy_doc.json

  tags = {
    Name    = "${var.project_name}-policy-lambda-execution"
    project = var.project_name
  }
}

# Attach Lambda Policy to Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}


# ################################################
# IAM module to create roles and policies for Glue
# ################################################

# Trust policy for Glue role
data "aws_iam_policy_document" "glue_trust_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM Role for Glue
resource "aws_iam_role" "glue_role" {
  name               = "${var.project_name}-role-glue"
  assume_role_policy = data.aws_iam_policy_document.glue_trust_policy.json

  tags = {
    Name    = "${var.project_name}-role-glue"
    project = var.project_name
  }
}

# Permission policy document for Glue
data "aws_iam_policy_document" "glue_policy_doc" {
  statement {
    sid    = "FullEC2NetworkingForGlue"
    effect = "Allow"
    actions = [
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeRouteTables",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterfacePermission",
      "ec2:CreateTags",
      "ec2:DescribeVpcs",
      "ec2:DescribeAvailabilityZones"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "GlueConnectionAndCatalogAccess"
    effect = "Allow"
    actions = [
      "glue:GetConnection",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:CreatePartition",
      "glue:BatchCreatePartition",
      "glue:BatchGetPartition",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:CreateConnection",
      "glue:UpdateConnection"
    ]
    resources = [
      "arn:aws:glue:${var.aws_region}:${var.account_id}:catalog",
      "arn:aws:glue:${var.aws_region}:${var.account_id}:database/*",
      "arn:aws:glue:${var.aws_region}:${var.account_id}:table/*/*",
      "arn:aws:glue:${var.aws_region}:${var.account_id}:connection/*"
    ]
  }

  statement {
    sid    = "S3AccessForDataAndScripts"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:GetBucketAcl",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*",
      "arn:aws:s3:::aws-glue-assets-${var.account_id}-${var.aws_region}",
      "arn:aws:s3:::aws-glue-assets-${var.account_id}-${var.aws_region}/*"
    ]
  }

  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/prj-01/glue-jobs:*",
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws-glue/crawlers:*"
    ]
  }

  statement {
    sid    = "SecretsManagerAccessForRDS"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${var.account_id}:secret:rds!*"
    ]
  }
}

# IAM Policy for Glue
resource "aws_iam_policy" "glue_policy" {
  name        = "${var.project_name}-policy-glue"
  description = "Policy for Glue to access S3, VPC, Catalog, CloudWatch and Secrets Manager"
  policy      = data.aws_iam_policy_document.glue_policy_doc.json

  tags = {
    Name    = "${var.project_name}-policy-glue"
    project = var.project_name
  }
}

# Attach Glue Policy to Glue Role
resource "aws_iam_role_policy_attachment" "glue_policy_attachment" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_policy.arn
}


# ##########################################################
# IAM module to create roles and policies for Step-Functions
# ##########################################################

# Trust policy for Step Functions role
data "aws_iam_policy_document" "step_functions_trust_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM Role for Step Functions
resource "aws_iam_role" "step_functions_role" {
  name               = "${var.project_name}-role-step-functions"
  assume_role_policy = data.aws_iam_policy_document.step_functions_trust_policy.json

  tags = {
    Name    = "${var.project_name}-role-step-functions"
    project = var.project_name
  }
}

# Permission policy document for Step Functions
data "aws_iam_policy_document" "step_functions_policy_doc" {
  statement {
    sid    = "StepFunctionLogging"
    effect = "Allow"
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowStepFunctionToRunGlueJob"
    effect = "Allow"
    actions = [
      "glue:StartJobRun",
      "glue:GetJobRun",
      "glue:BatchStopJobRun",
      "glue:StartCrawler",
      "glue:GetCrawler"
    ]
    resources = [
      "arn:aws:glue:${var.aws_region}:${var.account_id}:job/*",
      "arn:aws:glue:${var.aws_region}:${var.account_id}:crawler/*"
    ]
  }

  statement {
    sid    = "AllowStepFunctionToPassGlueRole"
    effect = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      "arn:aws:iam::${var.account_id}:role/${var.project_name}-role-glue"
    ]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["glue.amazonaws.com"]
    }
  }

  statement {
    sid    = "AllowStepFunctionToInvokeLambda"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      "arn:aws:lambda:${var.aws_region}:${var.account_id}:function:${var.project_name}-*"
    ]
  }

  statement {
    sid    = "EventBridgeAccessForSyncRuns"
    effect = "Allow"
    actions = [
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule"
    ]
    resources = [
      "arn:aws:events:${var.aws_region}:${var.account_id}:rule/StepFunctionsGetEventsForGlueJobRunRule"
    ]
  }
}

# IAM Policy for Step Functions
resource "aws_iam_policy" "step_functions_policy" {
  name        = "${var.project_name}-policy-step-functions"
  description = "Policy for Step Functions to invoke Lambda, run Glue jobs and log to CloudWatch"
  policy      = data.aws_iam_policy_document.step_functions_policy_doc.json

  tags = {
    Name    = "${var.project_name}-policy-step-functions"
    project = var.project_name
  }
}

# Attach Step Functions Policy to Step Functions Role
resource "aws_iam_role_policy_attachment" "step_functions_policy_attachment" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.step_functions_policy.arn
}


# ###############################################
# IAM module to create roles and policies for RDS
# ###############################################

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring_role" {
  name = "${var.project_name}-role-rds-monitoring"

  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_trust_policy.json

  tags = {
    Name    = "${var.project_name}-role-rds-monitoring"
    project = var.project_name
  }
}

# Trust policy for RDS monitoring role
data "aws_iam_policy_document" "rds_monitoring_trust_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Attach AWS managed policy
resource "aws_iam_role_policy_attachment" "rds_monitoring_policy" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

