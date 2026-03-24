#!/bin/bash
# ================================================
# GitHub Actions OIDC Setup Script
# Creates OIDC Provider + IAM Role + Policy
# Run once manually to bootstrap CI/CD
# ================================================

set -e  # Exit on any error

# Read parameters from wrapper script
ACCOUNT_ID="${1}"
REGION="${2}"
GITHUB_ORG="${3}"
GITHUB_REPO="${4}"
ROLE_NAME="${5}"
POLICY_NAME="${6}"

echo "================================================"
echo " GitHub Actions OIDC Bootstrap Setup"
echo " Account : ${ACCOUNT_ID}"
echo " Repo    : ${GITHUB_ORG}/${GITHUB_REPO}"
echo "================================================"

# ------------------------------------------------
# Step 1 - Create OIDC Identity Provider
# ------------------------------------------------
echo ""
echo ">>> Step 1: Creating OIDC Identity Provider..."

# Check if already exists
EXISTING_OIDC=$(aws iam list-open-id-connect-providers \
  --query "OpenIDConnectProviderList[?ends_with(Arn, 'token.actions.githubusercontent.com')].Arn" \
  --output text 2>/dev/null)

if [ -n "$EXISTING_OIDC" ]; then
  echo "OIDC Provider already exists: $EXISTING_OIDC"
  OIDC_ARN=$EXISTING_OIDC
else
  OIDC_ARN=$(aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
    --query 'OpenIDConnectProviderArn' \
    --output text)
  echo "OIDC Provider created: $OIDC_ARN"
fi

# ------------------------------------------------
# Step 2 - Create Trust Policy
# ------------------------------------------------
echo ""
echo ">>> Step 2: Creating Trust Policy..."

TRUST_POLICY=$(cat << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "$OIDC_ARN"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:$GITHUB_ORG/$GITHUB_REPO:*"
        }
      }
    }
  ]
}
EOF
)

echo "Trust Policy created!"
echo $TRUST_POLICY | python3 -m json.tool

# ------------------------------------------------
# Step 3 - Create IAM Role
# ------------------------------------------------
echo ""
echo ">>> Step 3: Creating IAM Role..."

# Check if role already exists
EXISTING_ROLE=$(aws iam get-role \
  --role-name $ROLE_NAME \
  --query 'Role.Arn' \
  --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_ROLE" ]; then
  echo "Role already exists: $EXISTING_ROLE"
  ROLE_ARN=$EXISTING_ROLE
else
  ROLE_ARN=$(aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document "$TRUST_POLICY" \
    --description "Role for GitHub Actions to run Terraform for $GITHUB_REPO" \
    --query 'Role.Arn' \
    --output text)
  echo "Role created: $ROLE_ARN"
fi

# ------------------------------------------------
# Step 4 - Create Permissions Policy
# ------------------------------------------------
echo ""
echo ">>> Step 4: Creating Permissions Policy..."

PERMISSIONS_POLICY=$(cat << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EC2Access",
      "Effect": "Allow",
      "Action": ["ec2:*"],
      "Resource": "*"
    },
    {
      "Sid": "IAMAccess",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:ListRoles",
        "iam:PassRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListPolicyVersions",
        "iam:ListAttachedRolePolicies",
        "iam:ListRolePolicies",
        "iam:GetRolePolicy",
        "iam:CreateOpenIDConnectProvider",
        "iam:GetOpenIDConnectProvider",
        "iam:ListOpenIDConnectProviders",
        "iam:TagRole",
        "iam:TagPolicy",
        "iam:ListInstanceProfilesForRole"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3Access",
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": "*"
    },
    {
      "Sid": "LambdaAccess",
      "Effect": "Allow",
      "Action": ["lambda:*"],
      "Resource": "*"
    },
    {
      "Sid": "GlueAccess",
      "Effect": "Allow",
      "Action": ["glue:*"],
      "Resource": "*"
    },
    {
      "Sid": "RDSAccess",
      "Effect": "Allow",
      "Action": ["rds:*"],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchAccess",
      "Effect": "Allow",
      "Action": [
        "logs:*",
        "cloudwatch:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "StepFunctionsAccess",
      "Effect": "Allow",
      "Action": ["states:*"],
      "Resource": "*"
    },
    {
      "Sid": "SecretsManagerAccess",
      "Effect": "Allow",
      "Action": ["secretsmanager:*"],
      "Resource": "*"
    },
    {
      "Sid": "DynamoDBAccess",
      "Effect": "Allow",
      "Action": ["dynamodb:*"],
      "Resource": "*"
    },
    {
      "Sid": "KMSAccess",
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey",
        "kms:CreateGrant",
        "kms:ListAliases",
        "kms:CreateKey",
        "kms:ScheduleKeyDeletion",
        "kms:GetKeyPolicy",
        "kms:PutKeyPolicy",
        "kms:TagResource",
        "kms:ListResourceTags"
      ],
      "Resource": "*"
    }
  ]
}
EOF
)

# Check if policy already exists
EXISTING_POLICY=$(aws iam get-policy \
  --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME" \
  --query 'Policy.Arn' \
  --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_POLICY" ]; then
  echo "Policy already exists: $EXISTING_POLICY"
  POLICY_ARN=$EXISTING_POLICY
else
  POLICY_ARN=$(aws iam create-policy \
    --policy-name $POLICY_NAME \
    --policy-document "$PERMISSIONS_POLICY" \
    --description "Permissions for GitHub Actions Terraform deployments" \
    --query 'Policy.Arn' \
    --output text)
  echo "Policy created: $POLICY_ARN"
fi

# ------------------------------------------------
# Step 5 - Attach Policy to Role
# ------------------------------------------------
echo ""
echo ">>> Step 5: Attaching Policy to Role..."
aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn $POLICY_ARN
echo "Policy attached!"

# ------------------------------------------------
# Done! Print summary
# ------------------------------------------------
echo ""
echo "================================================"
echo " Setup Complete!"
echo "================================================"
echo " OIDC Provider ARN : $OIDC_ARN"
echo " Role ARN          : $ROLE_ARN"
echo " Policy ARN        : $POLICY_ARN"
echo ""
echo " Add this to your GitHub Actions workflow:"
echo " role-to-assume: $ROLE_ARN"
echo "================================================"