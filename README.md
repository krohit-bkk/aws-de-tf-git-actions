# 🏗️ AWS Data Engineering Pipeline - Infrastructure as Code (Terraform)

A fully automated, production-grade **AWS Data Engineering pipeline** built entirely with Terraform. This project provisions a complete end-to-end DE pipeline - from raw data ingestion to harmonized storage in RDS MySQL - orchestrated by AWS Step Functions.

> *"Change one value in `terraform.tfvars`, run `terraform apply` and your entire pipeline is live in any AWS account."*

---

## 🏛️ Architecture Overview

```
                        ┌───────────────────────────────────────────┐
                        │         AWS Step Functions                │
                        │                                           │
                        │  Lambda 1 --> Lambda 2 --> Glue ETL 1     │
                        │    --> Glue ETL 2 --> Crawlers (RDS & S3) │
                        └───────────────────────────────────────────┘
                                               │
                   ┌───────────────────────────┼────────────────────────┐
                   ▼                           ▼                        ▼
          ┌────────────────┐         ┌──────────────────┐    ┌─────────────────┐
          │   S3 Bucket    │         │   RDS MySQL      │    │  Glue Catalog   │
          │                │         │                  │    │                 │
          │ /raw/accounts  │         │ project_01 DB    │    │ tf_prj_01_db_   │
          │ /raw/customers │         │ customer_to_     │    │ on_s3           │
          │ /harmonized/   │         │ accounts table   │    │ tf_prj_01_db_   │
          │ /curated/      │         │                  │    │ on_rds          │
          └────────────────┘         └──────────────────┘    └─────────────────┘
                   │                                                    │
                   └────────────────────────────────────────────────────┘
                                               │
                                               ▼
                                       ┌──────────────┐
                                       │    Athena    │
                                       │  (S3 data)   │
                                       └──────────────┘
```

### Data Flow
1. **Lambda 1** - Creates required folder structure in S3
2. **Lambda 2** - Downloads sample CSV files from remote URL --> uploads to S3
3. **Glue ETL 1** - Reads raw CSVs --> joins customers + accounts --> writes Parquet to S3
4. **Glue ETL 2** - Reads harmonized Parquet --> pushes to RDS MySQL
5. **Glue Crawlers** - Catalogs S3 and RDS data in parallel into Glue Data Catalog
6. **Athena** - Query S3 data via Glue Catalog (comes wired out of the box!)

---

## 📁 Project Structure

```
AWS_DE_TF/
├── providers.tf              # Provider & Terraform version config
├── main.tf                   # Root module - wires all modules together
├── variables.tf              # Root level variable declarations
├── outputs.tf                # Root level outputs
├── terraform.tfvars          # Variable values (ensure gitignored for production)
├── .gitignore
│
├── .github/
│   └── workflows/
│       ├── tf-plan.yml       # Runs terraform plan on PR
│       ├── tf-apply.yml      # Runs terraform apply on merge to main
│       └── tf-destroy.yml    # Manual destroy workflow
│
├── scripts/
│   ├── cleanup.sh            # Manual AWS resource cleanup script
│   └── setup_oidc_github_actions/
│       ├── github_actions_oidc_role_setup.sh
│       ├── github_actions_oidc_role_setup_wrapper_example.sh
│       └── terraform_state_management_setup.sh
│
└── modules/
    ├── networking/           # VPC, Subnets, IGW, NAT GW, Route Tables, SG, S3 Endpoint
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── iam/                  # All IAM Roles & Policies
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── cloudwatch/           # CloudWatch Log Groups
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── s3/                   # S3 Bucket + security configs
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── lambda/               # Lambda Functions + Python code packaging
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── functions/
    │       ├── create_s3_folders/
    │       │   └── lambda_function.py
    │       └── ingest_files_to_s3/
    │           └── lambda_function.py
    │
    ├── rds/                  # RDS MySQL Instance + Subnet Group
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── glue/                 # Glue Jobs, Crawlers, Connections, Catalog DBs
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── scripts/
    │       ├── merge_customers_accounts.py
    │       └── push_to_rds.py
    │
    └── step_functions/       # Step Functions State Machine
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## ✅ Prerequisites

| Requirement | Version |
|---|---|
| Terraform | >= 1.6.0 |
| AWS CLI | >= 2.x |
| Python | 3.12 |
| AWS Account | Free tier works! |

**AWS CLI must be configured with appropriate permissions:**
```bash
aws configure
```

---

## 🛠️ AWS Services Used

| Service | Purpose |
|---|---|
| **VPC** | Isolated network for all resources |
| **S3** | Raw, harmonized and curated data storage |
| **Lambda** | Folder creation + file ingestion |
| **AWS Glue** | ETL jobs, crawlers, data catalog |
| **RDS MySQL** | Harmonized data storage for transactional queries |
| **Step Functions** | Pipeline orchestration |
| **CloudWatch** | Centralized logging |
| **Secrets Manager** | RDS credentials management |
| **IAM** | Roles and policies for all services |
| **NAT Gateway** | Internet access for VPC-bound Lambda |
| **S3 Gateway Endpoint** | Private S3 access from within VPC |
| **Athena** | Ad-hoc querying on S3 data (via Glue Catalog) |

---

## 📦 Modules Description

### `networking`
Creates the full network layer: VPC (`192.168.0.0/16`), 4 subnets across 2 AZs (`ap-south-1a` and `ap-south-1c`), Internet Gateway, NAT Gateway, public/private Route Tables, Security Group and S3 Gateway Endpoint.

### `iam`
Creates all IAM roles and policies: Lambda execution role, Glue service role, Step Functions orchestration role and RDS enhanced monitoring role. All policies are defined using `aws_iam_policy_document` data sources for clean, validated HCL.

### `cloudwatch`
Creates 4 CloudWatch Log Groups with 14-day retention: `/aws/{project}/lambda`, `/aws/{project}/step-functions`, `/aws/{project}/glue-jobs`, `/aws/{project}/glue-crawler`.

### `s3`
Creates the main S3 bucket with versioning, AES256 server-side encryption and public access block. Glue PySpark scripts are uploaded here by the Glue module.

### `lambda`
Packages and deploys 2 Lambda functions (Python 3.12) using `archive_file`. Both are VPC-attached: Lambda 1 in public subnets (S3 via Gateway Endpoint), Lambda 2 in private subnets (internet via NAT Gateway).

### `rds`
Creates a private RDS MySQL 8.0 instance (`db.t4g.micro`, 20GB gp2) in `ap-south-1c`. Credentials are managed automatically by AWS Secrets Manager via `manage_master_user_password = true`.

### `glue`
Creates 2 Glue ETL jobs, 2 Glue Crawlers, 2 Glue Catalog Databases, 1 VPC network connection and 1 JDBC RDS connection. PySpark scripts are uploaded to S3 automatically.

### `step_functions`
Creates a Standard state machine using **JSONata** query language that orchestrates the full pipeline: 2 Lambda invocations --> 2 Glue ETL jobs (sequential) --> 2 Glue Crawlers (parallel).

---

## 🚀 Quick Start

### 1. Clone the repository
```bash
git clone https://github.com/krohit-bkk/aws-de-tf-git-actions.git
cd aws-de-tf-git-actions
```

### 2. Bootstrap - One time manual setup (OIDC + Remote State)
```bash
# Copy and configure the wrapper
cp scripts/setup_oidc_github_actions/github_actions_oidc_role_setup_wrapper_example.sh \
   scripts/setup_oidc_github_actions/github_actions_oidc_role_setup_wrapper.sh
```

# Edit with your values (account ID, region, repo name etc.)
`scripts/setup_oidc_github_actions/github_actions_oidc_role_setup_wrapper.sh`

```bash
# Run bootstrap
bash scripts/setup_oidc_github_actions/github_actions_oidc_role_setup_wrapper.sh
```

This creates:
- ✅ AWS OIDC Identity Provider for GitHub
- ✅ IAM Role for GitHub Actions (`github-actions-tf-role`)
- ✅ S3 bucket for Terraform remote state
- ✅ DynamoDB table for state locking

### 3. Add GitHub Secrets
```
GitHub --> repo --> Settings --> Secrets and variables --> Actions

Add these secrets:
  AWS_REGION            = ap-south-1
  TF_VAR_account_id     = YOUR_AWS_ACCOUNT_ID
  TF_VAR_s3_bucket_name = YOUR_UNIQUE_BUCKET_NAME
  TF_VAR_project_name   = tf-prj-01
```

### 4. Deploy via GitHub Actions (recommended)
```bash
# Create a feature branch
git checkout -b feature/my-change

# Make your changes, commit and push
git push origin feature/my-change
```

Create PR on GitHub --> triggers terraform plan --> review plan in PR comment
Merge to main --> triggers terraform apply automatically!

### 5. Deploy locally (alternative)
Note: For this to work, do ensure you have your AWS CLI configured in your local machine with correct access keys and secrets to your AWS account.

```bash
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
terraform init
terraform plan
terraform apply
```

> ⏱️ **Expected time:** ~15 minutes (RDS takes the longest at ~8 minutes)

### 6. Trigger the pipeline

```bash
aws stepfunctions start-execution \
  --state-machine-arn "arn:aws:states:<region>:<account-id>:stateMachine:<project-name>-step-function-01" \
  --name "my-first-run" \
  --input '{}'
```

---

## ⚙️ Configuration

All configurable values live in `terraform.tfvars`:

| Variable | Description | Required | Default |
|---|---|---|---|
| `aws_region` | AWS region to deploy to | ✅ | `ap-south-1` |
| `project_name` | Prefix for all resource names | ✅ | `tf-prj-01` |
| `account_id` | Your AWS account ID | ✅ | - |
| `s3_bucket_name` | Unique S3 bucket name | ✅ | - |

> 💡 To redeploy in a different AWS account - change `account_id` and `s3_bucket_name`. Everything else cascades automatically!

---

## 🔁 CI/CD Pipeline (GitHub Actions)

This repo uses GitHub Actions with **OIDC authentication** - no static AWS credentials stored anywhere!

```
Developer creates PR
        ↓
GitHub Actions runs terraform plan
        ↓
Plan output posted as PR comment
        ↓
PR reviewed & merged to main
        ↓
GitHub Actions runs terraform apply
        ↓
AWS infrastructure updated! ✅
```

### Workflows

| Workflow | Trigger | Action |
|---|---|---|
| `tf-plan.yml` | Pull Request to `main` | `terraform plan` + posts output as PR comment |
| `tf-apply.yml` | Push/merge to `main` | `terraform apply -auto-approve` |
| `tf-destroy.yml` | Manual (`workflow_dispatch`) | `terraform destroy` - requires typing `DESTROY` |

### OIDC Authentication Flow
```
GitHub Actions
      ↓
Generates short-lived OIDC token
      ↓
AWS validates token against GitHub OIDC provider
      ↓
Assumes github-actions-tf-role (temporary credentials)
      ↓
Runs Terraform with those credentials
      ↓
Credentials expire after job finishes ✅
```

### Remote State
```hcl
backend "s3" {
  bucket         = "tf-state-kr-de-analytics"
  key            = "terraform.tfstate"
  region         = "ap-south-1"
  dynamodb_table = "tf-state-lock"
  encrypt        = true
}
```

---

## 🔄 Pipeline Flow

```
START
  │
  ▼
[State 1] Invoke_Folder_Creation_on_S3
  Lambda creates: data/raw/accounts/, data/raw/customers/,
                  data/harmonized/customers_to_accounts/, data/curated/
  │
  ▼
[State 2] Ingest_Files_to_S3
  Lambda downloads sample_accounts.csv + sample_customers.csv
  from GitHub Gist --> uploads to S3 under date partition
  │
  ▼
[State 3] Trigger_Glue_ETL_1 (sync - waits for completion)
  Glue reads CSVs --> inner joins on customer_id -->
  writes Parquet partitioned by run_date
  │
  ▼
[State 4] Trigger_Glue_ETL_2 (sync - waits for completion)
  Glue reads Parquet --> writes to RDS MySQL customer_to_accounts table -->
  verification read-back to S3
  │
  ▼
[State 5] Trigger_Crawlers (parallel)
  ├── S3 Crawler  --> catalogs S3 harmonized data --> tf_prj_01_db_on_s3
  └── RDS Crawler --> catalogs RDS tables         --> tf_prj_01_db_on_rds
  │
  ▼
END ✅
```

---

## 🗑️ Destroying Infrastructure

### Via GitHub Actions (recommended):
```
GitHub --> Actions --> Terraform Destroy --> Run workflow --> Type "DESTROY" --> Run
```

### Via CLI:
```bash
terraform destroy
```

> ⚠️ **Important warnings before destroying:**
> - S3 bucket has `force_destroy = true` - all objects will be deleted!
> - RDS has `skip_final_snapshot = true` - no backup is taken!
> - NAT Gateway has an Elastic IP - both will be released
> - Subnet deletion can take 5-15 minutes due to Lambda ENI cleanup - **be patient!**

---

## 💡 Known Issues & Lessons Learned

| Issue | Root Cause | Fix |
|---|---|---|
| Subnet deletion stuck 15+ mins | Lambda ENIs blocking deletion | Run `terraform destroy` (destroys Lambda first) |
| RDS subnet group AZ error | Subnets in wrong AZs | Always document exact AZ names |
| Glue job failing with SG error | Missing all-port TCP self rule | Add `0-65535 TCP self` ingress rule |
| Step Functions crawler ARN invalid | `glue:startCrawler` doesn't exist | Use `aws-sdk:glue:startCrawler` |
| JSONata + ResultPath conflict | `ResultPath` is JSONPath-only | Remove `ResultPath` when using JSONata |
| State lost in CI/CD | No remote state configured | Always set up S3 backend before CI/CD |
| Duplicate resources on re-apply | Fresh VM has no state | Remote state in S3 + DynamoDB locking |

---

## 🔮 Future Improvements

- [ ] **Bastion host module** - EC2 instance setup for private RDS access for data checks and analytics
- [ ] **Multi-environment support** - `dev`, `staging`, `prod` workspaces
- [ ] **Cost estimation** - Infracost integration in CI/CD
- [ ] **Terraform modules versioning** - Pin module versions for stability
- [ ] **Athena Federated Query** - Direct RDS querying from Athena
- [ ] **LocalStack** - Local AWS simulation for testing before deployment

---

## 📚 Key Terraform Concepts Used

| Concept | Where Used |
|---|---|
| `for_each` with maps | Subnets, log groups, Lambda functions, Glue jobs |
| `locals` | Glue connection names, database names, state machine definition |
| `archive_file` data source | Lambda code packaging |
| `aws_iam_policy_document` | All IAM policies |
| `depends_on` | NAT Gateway --> IGW, Glue jobs --> S3 scripts |
| Module outputs | Cross-module resource references |
| `replace()` function | Subnet tag names, Glue database names |
| `jsonencode()` | Step Functions state machine definition |
| Remote backend | S3 + DynamoDB for state management |
| OIDC | Keyless GitHub Actions authentication |

---

## 👤 Author

**Kumar Rohit**
- GitHub: [@krohit-bkk](https://github.com/krohit-bkk)

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

> *Built with ❤️, lots of `terraform apply` and the occasional `terraform destroy`* 😄