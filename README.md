# 🏗️ AWS Data Engineering Pipeline — Infrastructure as Code (Terraform)

A fully automated, production-grade **AWS Data Engineering pipeline** built entirely with Terraform. This project provisions a complete end-to-end DE pipeline — from raw data ingestion to harmonized storage in RDS MySQL — orchestrated by AWS Step Functions.

> *"Change one value in `terraform.tfvars`, run `terraform apply`, and your entire pipeline is live in any AWS account."*

---

## 🏛️ Architecture Overview

```
                        ┌──────────────────────────────────────────┐
                        │         AWS Step Functions               │
                        │                                          │
                        │  Lambda 1 → Lambda 2 → Glue ETL 1        │
                        │    → Glue ETL 2 → Crawlers (RDS & S3)    │
                        └──────────────────────────────────────────┘
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
1. **Lambda 1** — Creates required folder structure in S3
2. **Lambda 2** — Downloads sample CSV files from remote URL → uploads to S3
3. **Glue ETL 1** — Reads raw CSVs → joins customers + accounts → writes Parquet to S3
4. **Glue ETL 2** — Reads harmonized Parquet → pushes to RDS MySQL
5. **Glue Crawlers** — Catalogs S3 and RDS data in parallel into Glue Data Catalog
6. **Athena** — Query S3 data via Glue Catalog (comes wired out of the box!)

---

## 📁 Project Structure

```
AWS_DE_TF/
├── providers.tf              # Provider & Terraform version config
├── main.tf                   # Root module — wires all modules together
├── variables.tf              # Root level variable declarations
├── outputs.tf                # Root level outputs
├── terraform.tfvars          # Variable values (ensure gitignored for production)
├── .gitignore
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
Creates the full network layer: VPC (`192.168.0.0/16`), 4 subnets across 2 AZs (`ap-south-1a` and `ap-south-1c`), Internet Gateway, NAT Gateway, public/private Route Tables, Security Group, and S3 Gateway Endpoint.

### `iam`
Creates all IAM roles and policies: Lambda execution role, Glue service role, Step Functions orchestration role, and RDS enhanced monitoring role. All policies are defined using `aws_iam_policy_document` data sources for clean, validated HCL.

### `cloudwatch`
Creates 4 CloudWatch Log Groups with 14-day retention: `/aws/{project}/lambda`, `/aws/{project}/step-functions`, `/aws/{project}/glue-jobs`, `/aws/{project}/glue-crawler`.

### `s3`
Creates the main S3 bucket with versioning, AES256 server-side encryption, and public access block. Glue PySpark scripts are uploaded here by the Glue module.

### `lambda`
Packages and deploys 2 Lambda functions (Python 3.12) using `archive_file`. Both are VPC-attached: Lambda 1 in public subnets (S3 via Gateway Endpoint), Lambda 2 in private subnets (internet via NAT Gateway).

### `rds`
Creates a private RDS MySQL 8.0 instance (`db.t4g.micro`, 20GB gp2) in `ap-south-1c`. Credentials are managed automatically by AWS Secrets Manager via `manage_master_user_password = true`.

### `glue`
Creates 2 Glue ETL jobs, 2 Glue Crawlers, 2 Glue Catalog Databases, 1 VPC network connection, and 1 JDBC RDS connection. PySpark scripts are uploaded to S3 automatically.

### `step_functions`
Creates a Standard state machine using **JSONata** query language that orchestrates the full pipeline: 2 Lambda invocations → 2 Glue ETL jobs (sequential) → 2 Glue Crawlers (parallel).

---

## 🚀 Quick Start

### 1. Clone the repository
```bash
git clone https://github.com/krohit-bkk/aws-de-tf.git
cd aws-de-tf
```

### 2. Configure variables
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
aws_region     = "ap-south-1"
project_name   = "tf-prj-01"
account_id     = "YOUR_AWS_ACCOUNT_ID"
s3_bucket_name = "YOUR_UNIQUE_BUCKET_NAME"
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Preview the plan
```bash
terraform plan
```

### 5. Apply
```bash
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
| `account_id` | Your AWS account ID | ✅ | — |
| `s3_bucket_name` | Unique S3 bucket name | ✅ | — |

> 💡 To redeploy in a different AWS account — change `account_id` and `s3_bucket_name`. Everything else cascades automatically!

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
  from GitHub Gist → uploads to S3 under date partition
  │
  ▼
[State 3] Trigger_Glue_ETL_1 (sync — waits for completion)
  Glue reads CSVs → inner joins on customer_id →
  writes Parquet partitioned by run_date
  │
  ▼
[State 4] Trigger_Glue_ETL_2 (sync — waits for completion)
  Glue reads Parquet → writes to RDS MySQL customer_to_accounts table →
  verification read-back to S3
  │
  ▼
[State 5] Trigger_Crawlers (parallel)
  ├── S3 Crawler  → catalogs S3 harmonized data → tf_prj_01_db_on_s3
  └── RDS Crawler → catalogs RDS tables         → tf_prj_01_db_on_rds
  │
  ▼
END ✅
```

---

## 🗑️ Destroying Infrastructure

```bash
terraform destroy
```

> ⚠️ **Important warnings before destroying:**
> - S3 bucket has `force_destroy = true` — all objects will be deleted!
> - RDS has `skip_final_snapshot = true` — no backup is taken!
> - NAT Gateway has an Elastic IP — both will be released
> - Subnet deletion can take 5-15 minutes due to Lambda ENI cleanup — **be patient!**

---


## 🔮 Future Improvements & Explorations

- [ ] **Bastion host module** — EC2 with SSM Session Manager for private RDS access (no keypair needed)
- [ ] **Remote state backend** — S3 + DynamoDB for team collaboration and state locking
- [ ] **CI/CD pipeline** — GitHub Actions for automated `terraform plan` on PR and `terraform apply` on merge
- [ ] **Multi-environment support** — `dev`, `staging`, `prod` workspaces
- [ ] **Cost estimation** — Infracost integration in CI/CD
- [ ] **Terraform modules versioning** — Pin module versions for stability

---

## 👤 Author

**Kumar Rohit**
- GitHub: [@krohit-bkk](https://github.com/krohit-bkk)

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

> *Built with ❤️, lots of `terraform apply` and the occasional `terraform destroy`* 😄
