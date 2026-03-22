# Setup networking
module "networking" {
  source = "./modules/networking"

  aws_region   = var.aws_region
  project_name = var.project_name
}

# Setup IAM
module "iam" {
  source         = "./modules/iam"
  project_name   = var.project_name
  account_id     = var.account_id
  aws_region     = var.aws_region
  s3_bucket_name = var.s3_bucket_name
}

# Setup CloudWatch
module "cloudwatch" {
  source       = "./modules/cloudwatch"
  project_name = var.project_name
}

# Setup S3
module "s3" {
  source         = "./modules/s3"
  project_name   = var.project_name
  s3_bucket_name = var.s3_bucket_name
}

# Setup Lambda
module "lambda" {
  source                = "./modules/lambda"
  project_name          = var.project_name
  aws_region            = var.aws_region
  s3_bucket_name        = var.s3_bucket_name
  lambda_role_arn       = module.iam.lambda_role_arn
  vpc_id                = module.networking.vpc_id
  subnet_ids            = module.networking.subnet_ids
  security_group_id     = module.networking.security_group_id
  lambda_log_group_name = module.cloudwatch.lambda_log_group_name
}

# Setup RDS
module "rds" {
  source                  = "./modules/rds"
  project_name            = var.project_name
  aws_region              = var.aws_region
  vpc_id                  = module.networking.vpc_id
  subnet_ids              = module.networking.subnet_ids
  security_group_id       = module.networking.security_group_id
  rds_monitoring_role_arn = module.iam.rds_monitoring_role_arn
}

# Setup Glue
module "glue" {
  source                   = "./modules/glue"
  project_name             = var.project_name
  aws_region               = var.aws_region
  account_id               = var.account_id
  s3_bucket_name           = var.s3_bucket_name
  glue_role_arn            = module.iam.glue_role_arn
  vpc_id                   = module.networking.vpc_id
  subnet_ids               = module.networking.subnet_ids
  security_group_id        = module.networking.security_group_id
  rds_endpoint             = module.rds.rds_endpoint
  rds_db_name              = module.rds.rds_db_name
  rds_secret_arn           = module.rds.rds_secret_arn
  glue_jobs_log_group_name = module.cloudwatch.glue_jobs_log_group_name
  depends_on               = [module.s3]    
}

# Setup Step Functions
module "step_functions" {
  source                       = "./modules/step_functions"
  project_name                 = var.project_name
  aws_region                   = var.aws_region
  account_id                   = var.account_id
  step_functions_role_arn      = module.iam.step_functions_role_arn
  step_functions_log_group_arn = module.cloudwatch.step_functions_log_group_arn
  lambda_function_arns         = module.lambda.lambda_function_arns
  glue_job_names               = module.glue.glue_job_names
  s3_crawler_name              = module.glue.s3_crawler_name
  rds_crawler_name             = module.glue.rds_crawler_name
}