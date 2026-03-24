#!/bin/bash
# ================================================
# Remote State Setup Script
# Creates S3 bucket + DynamoDB table for
# Terraform remote state management
# Run once manually to bootstrap remote state
# ================================================

set -e  # Exit on any error

# ------------------------------------------------
# Arguments
# ------------------------------------------------
ACCOUNT_ID=$1
REGION=$2
STATE_BUCKET=$3
DYNAMODB_TABLE=$4

# ------------------------------------------------
# Validate arguments
# ------------------------------------------------
if [ -z "$ACCOUNT_ID" ] || [ -z "$REGION" ] || [ -z "$STATE_BUCKET" ] || [ -z "$DYNAMODB_TABLE" ]; then
  echo "Usage: $0 <account_id> <region> <state_bucket> <dynamodb_table>"
  echo "Example: $0 123456789012 ap-south-1 bucket-name-for-tf-state dynamodb-table-for-tf-state-lock"
  exit 1
fi

echo "================================================"
echo " Remote State Bootstrap Setup"
echo " Account       : $ACCOUNT_ID"
echo " Region        : $REGION"
echo " State Bucket  : $STATE_BUCKET"
echo " DynamoDB Table: $DYNAMODB_TABLE"
echo "================================================"

# ------------------------------------------------
# Step 1 - Create S3 bucket for Terraform state
# ------------------------------------------------
echo ""
echo ">>> Step 1: Creating S3 bucket for Terraform state..."

EXISTING_BUCKET=$(aws s3api list-buckets \
  --query "Buckets[?Name=='$STATE_BUCKET'].Name" \
  --output text 2>/dev/null)

if [ -n "$EXISTING_BUCKET" ]; then
  echo "S3 bucket already exists: $STATE_BUCKET — skipping!"
else
  aws s3api create-bucket \
    --bucket $STATE_BUCKET \
    --region $REGION \
    --create-bucket-configuration LocationConstraint=$REGION
  echo "S3 bucket created: $STATE_BUCKET"
fi

# ------------------------------------------------
# Step 2 - Enable versioning
# ------------------------------------------------
echo ""
echo ">>> Step 2: Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket $STATE_BUCKET \
  --versioning-configuration Status=Enabled
echo "Versioning enabled!"

# ------------------------------------------------
# Step 3 - Enable encryption
# ------------------------------------------------
echo ""
echo ">>> Step 3: Enabling encryption on S3 bucket..."
aws s3api put-bucket-encryption \
  --bucket $STATE_BUCKET \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
echo "Encryption enabled!"

# ------------------------------------------------
# Step 4 - Block public access
# ------------------------------------------------
echo ""
echo ">>> Step 4: Blocking public access on S3 bucket..."
aws s3api put-public-access-block \
  --bucket $STATE_BUCKET \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
echo "Public access blocked!"

# ------------------------------------------------
# Step 5 - Create DynamoDB table for state locking
# ------------------------------------------------
echo ""
echo ">>> Step 5: Creating DynamoDB table for state locking..."

EXISTING_TABLE=$(aws dynamodb list-tables \
  --query "TableNames[?@=='$DYNAMODB_TABLE']" \
  --output text \
  --region $REGION 2>/dev/null)

if [ -n "$EXISTING_TABLE" ]; then
  echo "DynamoDB table already exists: $DYNAMODB_TABLE — skipping!"
else
  aws dynamodb create-table \
    --table-name $DYNAMODB_TABLE \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $REGION
  echo "DynamoDB table created: $DYNAMODB_TABLE"
fi

# ------------------------------------------------
# Done!
# ------------------------------------------------
echo ""
echo "================================================"
echo " Remote State Setup Complete!"
echo "================================================"
echo " State Bucket  : $STATE_BUCKET"
echo " DynamoDB Table: $DYNAMODB_TABLE"
echo ""
echo " Add this to your providers.tf:"
echo ""
echo ' terraform {'
echo '   backend "s3" {'
echo "     bucket         = \"$STATE_BUCKET\""
echo '     key            = "terraform.tfstate"'
echo "     region         = \"$REGION\""
echo "     dynamodb_table = \"$DYNAMODB_TABLE\""
echo '     encrypt        = true'
echo '   }'
echo ' }'
echo "================================================"