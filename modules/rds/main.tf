# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-rds-subnet-group"
  description = "Subnet group for ${var.project_name} RDS instance"
  subnet_ids  = [
    var.subnet_ids["subnet_1"],   # ap-south-1a
    var.subnet_ids["subnet_2"],   # ap-south-1c
    var.subnet_ids["subnet_3"],   # ap-south-1a
    var.subnet_ids["subnet_4"],   # ap-south-1c
  ]

  tags = {
    Name    = "${var.project_name}-rds-subnet-group"
    project = var.project_name
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-rds-mysql-01"
  engine            = "mysql"
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  # Storage autoscaling
  max_allocated_storage = var.db_max_allocated_storage

  # Database settings
  db_name  = var.db_name
  username = var.db_username

  # Credentials managed by Secrets Manager
  manage_master_user_password = true

  # Network settings
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  availability_zone      = "${var.aws_region}c"
  publicly_accessible    = false

  # Storage settings
  storage_type      = "gp2"
  storage_encrypted = true

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = var.rds_monitoring_role_arn

  # Other settings
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 1

  tags = {
    Name    = "${var.project_name}-rds-mysql-01"
    project = var.project_name
  }
}