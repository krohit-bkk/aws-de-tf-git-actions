#!/bin/bash
# ================================================
# AWS Manual Cleanup Script for tf-prj-01
# Run this when Terraform state is lost
# ================================================

PROJECT="tf-prj-01"
REGION="ap-south-1"
ACCOUNT_ID="428146723175"
S3_BUCKET="tf-kr-de-analytics-demo-np-01"

echo "================================================"
echo " Starting cleanup for project: $PROJECT"
echo "================================================"

# ------------------------------------------------
# Step 1 - Delete Step Functions
# ------------------------------------------------
echo ""
echo ">>> Step 1: Deleting Step Functions..."
aws stepfunctions delete-state-machine \
  --state-machine-arn "arn:aws:states:$REGION:$ACCOUNT_ID:stateMachine:$PROJECT-step-function-01" \
  --region $REGION
echo "Done!"

# ------------------------------------------------
# Step 2 - Delete Lambda Functions
# ------------------------------------------------
echo ""
echo ">>> Step 2: Deleting Lambda Functions..."
aws lambda delete-function \
  --function-name "$PROJECT-001-create-ingestion-folders-on-s3" \
  --region $REGION
aws lambda delete-function \
  --function-name "$PROJECT-002-ingest-files-to-s3" \
  --region $REGION
echo "Done!"

# ------------------------------------------------
# Step 3 - Delete Glue Jobs
# ------------------------------------------------
echo ""
echo ">>> Step 3: Deleting Glue Jobs..."
aws glue delete-job --job-name "$PROJECT-01-merge-customers-accounts" --region $REGION
aws glue delete-job --job-name "$PROJECT-02-push-to-rds" --region $REGION
echo "Done!"

# ------------------------------------------------
# Step 4 - Delete Glue Crawlers
# ------------------------------------------------
echo ""
echo ">>> Step 4: Deleting Glue Crawlers..."
aws glue delete-crawler --name "$PROJECT-03-glue-crawler-s3-01" --region $REGION
aws glue delete-crawler --name "$PROJECT-04-glue-crawler-rds-01" --region $REGION
echo "Done!"

# ------------------------------------------------
# Step 5 - Delete Glue Connections
# ------------------------------------------------
echo ""
echo ">>> Step 5: Deleting Glue Connections..."
aws glue delete-connection \
  --connection-name "$PROJECT-conn-vpc" \
  --catalog-id $ACCOUNT_ID \
  --region $REGION
aws glue delete-connection \
  --connection-name "$PROJECT-conn-rds-mysql" \
  --catalog-id $ACCOUNT_ID \
  --region $REGION
echo "Done!"

# ------------------------------------------------
# Step 6 - Delete Glue Databases
# ------------------------------------------------
echo ""
echo ">>> Step 6: Deleting Glue Databases..."
aws glue delete-database --name "tf_prj_01_db_on_s3" --region $REGION
aws glue delete-database --name "tf_prj_01_db_on_rds" --region $REGION
echo "Done!"

# ------------------------------------------------
# Step 7 - Delete RDS Instance (takes 5-10 mins)
# ------------------------------------------------
echo ""
echo ">>> Step 7: Deleting RDS Instance (this takes 5-10 mins)..."
aws rds delete-db-instance \
  --db-instance-identifier "$PROJECT-rds-mysql-01" \
  --skip-final-snapshot \
  --region $REGION

echo "Waiting for RDS to be deleted..."
aws rds wait db-instance-deleted \
  --db-instance-identifier "$PROJECT-rds-mysql-01" \
  --region $REGION
echo "RDS deleted!"

# ------------------------------------------------
# Step 8 - Delete RDS Subnet Group
# ------------------------------------------------
echo ""
echo ">>> Step 8: Deleting RDS Subnet Group..."
aws rds delete-db-subnet-group \
  --db-subnet-group-name "$PROJECT-rds-subnet-group" \
  --region $REGION
echo "Done!"

# ------------------------------------------------
# Step 9 - Delete S3 Bucket (force delete all objects)
# ------------------------------------------------
echo ""
echo ">>> Step 9: Deleting S3 Bucket..."
aws s3 rb s3://$S3_BUCKET --force --region $REGION
echo "Done!"

# ------------------------------------------------
# Step 10 - Delete CloudWatch Log Groups
# ------------------------------------------------
echo ""
echo ">>> Step 10: Deleting CloudWatch Log Groups..."
aws logs delete-log-group --log-group-name "/aws/$PROJECT/lambda" --region $REGION
aws logs delete-log-group --log-group-name "/aws/$PROJECT/step-functions" --region $REGION
aws logs delete-log-group --log-group-name "/aws/$PROJECT/glue-jobs" --region $REGION
aws logs delete-log-group --log-group-name "/aws/$PROJECT/glue-crawler" --region $REGION
echo "Done!"

# ------------------------------------------------
# Step 11 - Delete IAM Role Policy Attachments
# ------------------------------------------------
echo ""
echo ">>> Step 11: Detaching IAM Policies..."
aws iam detach-role-policy \
  --role-name "$PROJECT-role-lambda" \
  --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/$PROJECT-policy-lambda-execution"
aws iam detach-role-policy \
  --role-name "$PROJECT-role-glue" \
  --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/$PROJECT-policy-glue"
aws iam detach-role-policy \
  --role-name "$PROJECT-role-step-functions" \
  --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/$PROJECT-policy-step-functions"
aws iam detach-role-policy \
  --role-name "$PROJECT-role-rds-monitoring" \
  --policy-arn "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
echo "Done!"

# ------------------------------------------------
# Step 12 - Delete IAM Policies
# ------------------------------------------------
echo ""
echo ">>> Step 12: Deleting IAM Policies..."
aws iam delete-policy \
  --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/$PROJECT-policy-lambda-execution"
aws iam delete-policy \
  --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/$PROJECT-policy-glue"
aws iam delete-policy \
  --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/$PROJECT-policy-step-functions"
echo "Done!"

# ------------------------------------------------
# Step 13 - Delete IAM Roles
# ------------------------------------------------
echo ""
echo ">>> Step 13: Deleting IAM Roles..."
aws iam delete-role --role-name "$PROJECT-role-lambda"
aws iam delete-role --role-name "$PROJECT-role-glue"
aws iam delete-role --role-name "$PROJECT-role-step-functions"
aws iam delete-role --role-name "$PROJECT-role-rds-monitoring"
echo "Done!"

# ------------------------------------------------
# Step 14 - Get VPC ID
# ------------------------------------------------
echo ""
echo ">>> Step 14: Getting VPC ID..."
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:project,Values=$PROJECT" \
  --query 'Vpcs[0].VpcId' \
  --output text \
  --region $REGION)
echo "VPC ID: $VPC_ID"

# ------------------------------------------------
# Step 15 - Delete NAT Gateway (expensive!)
# ------------------------------------------------
echo ""
echo ">>> Step 15: Deleting NAT Gateway..."
NAT_ID=$(aws ec2 describe-nat-gateways \
  --filter "Name=tag:project,Values=$PROJECT" \
  --query 'NatGateways[0].NatGatewayId' \
  --output text \
  --region $REGION)
echo "NAT Gateway ID: $NAT_ID"
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID --region $REGION

echo "Waiting for NAT Gateway to be deleted..."
aws ec2 wait nat-gateway-deleted \
  --nat-gateway-ids $NAT_ID \
  --region $REGION
echo "NAT Gateway deleted!"

# ------------------------------------------------
# Step 16 - Release Elastic IP
# ------------------------------------------------
echo ""
echo ">>> Step 16: Releasing Elastic IP..."
EIP_ALLOC=$(aws ec2 describe-addresses \
  --filters "Name=tag:project,Values=$PROJECT" \
  --query 'Addresses[0].AllocationId' \
  --output text \
  --region $REGION)
echo "EIP Allocation ID: $EIP_ALLOC"
aws ec2 release-address --allocation-id $EIP_ALLOC --region $REGION
echo "Done!"

# ------------------------------------------------
# Step 17 - Delete S3 VPC Endpoint
# ------------------------------------------------
echo ""
echo ">>> Step 17: Deleting S3 VPC Endpoint..."
ENDPOINT_ID=$(aws ec2 describe-vpc-endpoints \
  --filters "Name=tag:project,Values=$PROJECT" \
  --query 'VpcEndpoints[0].VpcEndpointId' \
  --output text \
  --region $REGION)
echo "Endpoint ID: $ENDPOINT_ID"
aws ec2 delete-vpc-endpoints \
  --vpc-endpoint-ids $ENDPOINT_ID \
  --region $REGION
echo "Done!"

# ------------------------------------------------
# Step 18 - Delete Route Table Associations & Route Tables
# ------------------------------------------------
echo ""
echo ">>> Step 18: Deleting Route Tables..."
RT_IDS=$(aws ec2 describe-route-tables \
  --filters "Name=tag:project,Values=$PROJECT" \
  --query 'RouteTables[*].RouteTableId' \
  --output text \
  --region $REGION)

for RT_ID in $RT_IDS; do
  # Disassociate subnets first
  ASSOC_IDS=$(aws ec2 describe-route-tables \
    --route-table-ids $RT_ID \
    --query 'RouteTables[0].Associations[?!Main].RouteTableAssociationId' \
    --output text \
    --region $REGION)
  for ASSOC_ID in $ASSOC_IDS; do
    echo "Disassociating $ASSOC_ID from $RT_ID..."
    aws ec2 disassociate-route-table --association-id $ASSOC_ID --region $REGION
  done
  # Delete route table
  echo "Deleting route table $RT_ID..."
  aws ec2 delete-route-table --route-table-id $RT_ID --region $REGION 2>/dev/null || echo "Skipping main route table"
done
echo "Done!"

# ------------------------------------------------
# Step 19 - Delete Security Group
# ------------------------------------------------
echo ""
echo ">>> Step 19: Deleting Security Group..."
SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=tag:project,Values=$PROJECT" \
  --query 'SecurityGroups[0].GroupId' \
  --output text \
  --region $REGION)
echo "Security Group ID: $SG_ID"
aws ec2 delete-security-group --group-id $SG_ID --region $REGION
echo "Done!"

# ------------------------------------------------
# Step 20 - Delete Subnets
# ------------------------------------------------
echo ""
echo ">>> Step 20: Deleting Subnets..."
SUBNET_IDS=$(aws ec2 describe-subnets \
  --filters "Name=tag:project,Values=$PROJECT" \
  --query 'Subnets[*].SubnetId' \
  --output text \
  --region $REGION)
for SUBNET_ID in $SUBNET_IDS; do
  echo "Deleting subnet $SUBNET_ID..."
  aws ec2 delete-subnet --subnet-id $SUBNET_ID --region $REGION
done
echo "Done!"

# ------------------------------------------------
# Step 21 - Detach and Delete Internet Gateway
# ------------------------------------------------
echo ""
echo ">>> Step 21: Deleting Internet Gateway..."
IGW_ID=$(aws ec2 describe-internet-gateways \
  --filters "Name=tag:project,Values=$PROJECT" \
  --query 'InternetGateways[0].InternetGatewayId' \
  --output text \
  --region $REGION)
echo "IGW ID: $IGW_ID"
aws ec2 detach-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --vpc-id $VPC_ID \
  --region $REGION
aws ec2 delete-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --region $REGION
echo "Done!"

# ------------------------------------------------
# Step 22 - Delete VPC
# ------------------------------------------------
echo ""
echo ">>> Step 22: Deleting VPC..."
aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION
echo "Done!"

# ------------------------------------------------
# Done!
# ------------------------------------------------
echo ""
echo "================================================"
echo " Cleanup complete for project: $PROJECT"
echo "================================================"