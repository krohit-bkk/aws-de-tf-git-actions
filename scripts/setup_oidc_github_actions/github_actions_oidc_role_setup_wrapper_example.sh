#!/bin/bash
# ================================================
# GitHub Actions OIDC Setup Script
# Creates OIDC Provider + IAM Role + Policy
# Run once manually to bootstrap CI/CD
# ================================================

set -e  # Exit on any error

ACCOUNT_ID="<your-aws-account-id>"
REGION="<your-aws-region>"
GITHUB_ORG="<your-github-organization>"
GITHUB_REPO="<your-github-repository>"
ROLE_NAME="github-actions-tf-role"
POLICY_NAME="github-actions-tf-policy"

SCRIPT_HOME="$(dirname "$(readlink -f "$0")")"

# Setup OIDC provider + IAM role + policy for GitHub Actions
bash ${SCRIPT_HOME}/github_actions_oidc_role_setup.sh ${ACCOUNT_ID} ${REGION} ${GITHUB_ORG} ${GITHUB_REPO} ${ROLE_NAME} ${POLICY_NAME}

# Setup up Terraform remote state management (S3 + DynamoDB)
STATE_BUCKET="tf-state-kr-de-analytics"
DYNAMODB_TABLE="tf-state-lock"
bash ${SCRIPT_HOME}/terraform_state_management_setup.sh ${ACCOUNT_ID} ${REGION} ${STATE_BUCKET} ${DYNAMODB_TABLE}
