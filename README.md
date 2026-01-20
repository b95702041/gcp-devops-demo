# GCP DevOps Demo - Complete Setup Guide (Updated with Correct Permissions)

A complete hands-on learning project for Google Cloud Platform DevOps, featuring CI/CD pipelines, Docker containerization, Infrastructure as Code with Terraform, and serverless deployment on Cloud Run.

**⚠️ IMPORTANT: This guide includes ALL required permissions discovered through testing.**

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#️-architecture)
3. [Prerequisites](#prerequisites)
4. [Complete Setup Guide](#complete-setup-guide)
5. [Testing & Verification](#-testing--verification)
6. [Monitoring & Debugging](#-monitoring--debugging)
7. [Troubleshooting](#troubleshooting)
8. [Cleanup](#cleanup)
9. [Permissions Summary](#-complete-permissions-summary-least-privilege)
10. [What You've Learned](#-what-youve-learned)

---

## 🎯 Project Overview

This project demonstrates a complete modern DevOps workflow by deploying a Python Flask API to Google Cloud Run with automated CI/CD using **Workload Identity Federation** (no service account keys needed!).

### Key Technologies

- **Application**: Python Flask REST API
- **Containerization**: Docker with multi-stage builds
- **Infrastructure as Code**: Terraform
- **CI/CD**: GitHub Actions + Google Cloud Build
- **Authentication**: Workload Identity Federation (keyless!)
- **Container Registry**: Google Artifact Registry
- **Compute**: Google Cloud Run (serverless)
- **Region**: asia-east1 (Taiwan)

### What Gets Deployed

A simple Flask API with three endpoints:
- `GET /` - Welcome message with timestamp
- `GET /health` - Health check endpoint
- `GET /info` - Application metadata

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Repository                        │
│  ┌──────────┐  ┌───────────┐  ┌──────────┐  ┌───────────┐ │
│  │  Flask   │  │ Dockerfile│  │ Terraform│  │ CloudBuild│ │
│  │   App    │  │           │  │   IaC    │  │   Config  │ │
│  └──────────┘  └───────────┘  └──────────┘  └───────────┘ │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ git push (triggers pipeline)
                         ▼
              ┌──────────────────────┐
              │   GitHub Actions     │
              │  (Authenticate GCP)  │
              └──────────┬───────────┘
                         │
                         │ Submit Build
                         ▼
              ┌──────────────────────┐
              │    Cloud Build       │
              │  1. Build Docker     │
              │  2. Push to Registry │
              │  3. Deploy to Run    │
              └──────────┬───────────┘
                         │
          ┌──────────────┼──────────────┐
          │              │               │
          ▼              ▼               ▼
  ┌──────────────┐ ┌─────────┐  ┌──────────────┐
  │  Artifact    │ │  Cloud  │  │   Cloud Run  │
  │  Registry    │ │  Build  │  │   Service    │
  │  (Images)    │ │  (Logs) │  │ (Production) │
  └──────────────┘ └─────────┘  └──────┬───────┘
                                        │
                                        │ HTTPS
                                        ▼
                                 ┌──────────────┐
                                 │  Public API  │
                                 │ (Your Users) │
                                 └──────────────┘
```

### Project Structure

```
gcp-devops-demo/
├── app/
│   ├── main.py              # Flask application
│   └── requirements.txt     # Python dependencies
├── terraform/
│   ├── main.tf             # Infrastructure resources
│   ├── iam.tf              # IAM permissions (automated!)
│   ├── variables.tf        # Terraform variables
│   ├── outputs.tf          # Output values
│   └── terraform.tfvars    # Your configuration
├── .github/workflows/
│   └── deploy.yaml         # CI/CD pipeline
├── Dockerfile              # Container definition
├── cloudbuild.yaml         # Build configuration
└── README.md              # This file
```

### Deployment Process

1. **Developer pushes code** to GitHub
2. **GitHub Actions** authenticates using Workload Identity Federation
3. **Cloud Build** executes `cloudbuild.yaml`:
   - Builds Docker image from `Dockerfile`
   - Pushes image to Artifact Registry
   - Deploys to Cloud Run
4. **Cloud Run** serves the application to users

### Manual Deployment

If you want to deploy without GitHub Actions:

```bash
# Submit build directly to Cloud Build
gcloud builds submit \
  --config=cloudbuild.yaml \
  --substitutions=_REGION=asia-east1,_APP_NAME=gcp-devops-demo,SHORT_SHA=$(git rev-parse --short HEAD) \
  --project=$PROJECT_ID
```

---

## 📦 Prerequisites

### Required Accounts

1. **Google Cloud Platform Account**
   - Sign up: https://cloud.google.com/
   - Free tier includes $300 credit for new users
   - **Billing must be enabled**

2. **GitHub Account**
   - Sign up: https://github.com/join

### Required Tools

#### Windows Users:
- **Google Cloud SDK**: https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe
- **Git for Windows**: https://git-scm.com/download/win
- **Terraform**: https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_windows_amd64.zip

#### Mac/Linux Users:
```bash
# Google Cloud SDK
curl https://sdk.cloud.google.com | bash

# Terraform
brew install terraform  # macOS
# or download from: https://www.terraform.io/downloads

# Git
brew install git  # macOS
sudo apt-get install git  # Linux
```

---

## 🚀 Complete Setup Guide

### Step 1: Create GCP Project

1. Go to: https://console.cloud.google.com/
2. Click "Select a project" → "NEW PROJECT"
3. Name it (e.g., "My First Project")
4. Note your **Project ID** (e.g., `project-cde9aa72-04d5-4bd3-af5`)

### Step 2: Enable Billing

**⚠️ CRITICAL: Without billing, nothing will work!**

1. Go to: https://console.cloud.google.com/billing
2. Link your project to a billing account
3. New users get $300 free credit

### Step 3: Setup gcloud CLI

```powershell
# Windows PowerShell
gcloud init

# Login with your Google account
# Select your project
# Choose region: asia-east1-a

# Verify setup
gcloud config get-value project

# Set PATH (if gcloud not found)
$env:Path += ";C:\Users\$env:USERNAME\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin"
```

### Step 4: Create Service Account

```powershell
# Set your project ID
$env:PROJECT_ID = "your-project-id"  # Replace with YOUR actual project ID

# Create service account
gcloud iam service-accounts create github-actions-sa --display-name="GitHub Actions Service Account" --project=$env:PROJECT_ID
```

### Step 5: Create Service Account and Workload Identity Federation

**⚠️ Run these commands ONCE before running Terraform**

```bash
# Set your variables (replace with YOUR values)
export PROJECT_ID="your-project-id"  # e.g., project-cde9aa72-04d5-4bd3-af5
export GITHUB_USERNAME="your-github-username"  # e.g., b95702041
export GITHUB_REPO="gcp-devops-demo"

# Get project number
export PROJECT_NUMBER=$(gcloud projects list --filter="PROJECT_ID:$PROJECT_ID" --format="value(PROJECT_NUMBER)")

# Enable required APIs
gcloud services enable iamcredentials.googleapis.com --project=$PROJECT_ID
gcloud services enable sts.googleapis.com --project=$PROJECT_ID
gcloud services enable cloudbuild.googleapis.com --project=$PROJECT_ID
gcloud services enable run.googleapis.com --project=$PROJECT_ID
gcloud services enable artifactregistry.googleapis.com --project=$PROJECT_ID

# Create service account
gcloud iam service-accounts create github-actions-sa \
  --display-name="GitHub Actions Service Account" \
  --project=$PROJECT_ID

# Create Workload Identity Pool
gcloud iam workload-identity-pools create github-pool \
  --project=$PROJECT_ID \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create Workload Identity Provider
gcloud iam workload-identity-pools providers create-oidc github-provider \
  --project=$PROJECT_ID \
  --location="global" \
  --workload-identity-pool=github-pool \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner=='$GITHUB_USERNAME'" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Grant Workload Identity User role
gcloud iam service-accounts add-iam-policy-binding github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --project=$PROJECT_ID \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/$GITHUB_USERNAME/$GITHUB_REPO"

# Display WIF provider string (save this for GitHub secrets!)
echo "WIF_PROVIDER value for GitHub secrets:"
echo "projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider"
```

**Windows PowerShell users:** Replace `export` with `$env:` 
```powershell
$env:PROJECT_ID = "your-project-id"
$env:GITHUB_USERNAME = "your-github-username"
# ... etc
```

### Step 6: Add GitHub Secrets

The last command from Step 5 displayed the WIF provider string. Add these secrets to GitHub:

Go to: https://github.com/YOUR-USERNAME/gcp-devops-demo/settings/secrets/actions

Click "New repository secret" for each:

**Secret 1:**
- Name: `GCP_PROJECT_ID`
- Value: `your-project-id` (e.g., `project-cde9aa72-04d5-4bd3-af5`)

**Secret 2:**
- Name: `WIF_PROVIDER`
- Value: `projects/YOUR-PROJECT-NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider`

**Secret 3:**
- Name: `WIF_SERVICE_ACCOUNT`
- Value: `github-actions-sa@your-project-id.iam.gserviceaccount.com`

### Step 7: Deploy Infrastructure with Terraform

**This is where IAM permissions are automatically created!**

```powershell
cd terraform

# Copy example file
copy terraform.tfvars.example terraform.tfvars

# Edit with your project ID
notepad terraform.tfvars
# Change: project_id = "your-project-id"

# Authenticate Terraform
gcloud auth application-default login

# Deploy infrastructure AND grant IAM permissions automatically!
terraform init
terraform plan
terraform apply
# Type: yes
```

**What Terraform does:**
- ✅ Creates Cloud Run service
- ✅ Creates Artifact Registry repository
- ✅ Enables required APIs
- ✅ **Grants all IAM permissions automatically** (via `iam.tf`)
- ✅ Follows **Principle of Least Privilege**

No manual IAM configuration needed!

### Step 8: Setup GitHub Repository

1. **Create repository:** https://github.com/new
   - Name: `gcp-devops-demo`
   - **Don't** initialize with README

2. **Push code:**
```powershell
cd ..  # Back to project root
git init
git remote add origin https://github.com/YOUR-USERNAME/gcp-devops-demo.git
git add .
git commit -m "Initial commit: GCP DevOps with Workload Identity Federation"
git branch -M main
git push -u origin main --force
```

### Step 9: Add GitHub Secrets

Go to: https://github.com/YOUR-USERNAME/gcp-devops-demo/settings/secrets/actions

Click "New repository secret" for each:

**Secret 1:**
- Name: `GCP_PROJECT_ID`
- Value: `your-project-id`

**Secret 2:**
- Name: `WIF_PROVIDER`
- Value: `projects/YOUR-PROJECT-NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider`

**Secret 3:**
- Name: `WIF_SERVICE_ACCOUNT`
- Value: `github-actions-sa@your-project-id.iam.gserviceaccount.com`

### Step 10: Watch Deployment

1. Go to: https://github.com/YOUR-USERNAME/gcp-devops-demo/actions
2. Click on "Deploy to Google Cloud Run"
3. Watch the workflow (takes 5-10 minutes)
4. Wait for green checkmark ✅

### Step 11: Test Your Application

```powershell
# Get your service URL
gcloud run services describe gcp-devops-demo --region=asia-east1 --format="value(status.url)"

# Test endpoints
curl https://your-service-url/
curl https://your-service-url/health
curl https://your-service-url/info
```

---

## 🔧 Troubleshooting

### Common Issues

#### Permission Denied Errors

**Problem:** Build fails with permission errors

**Solution:** Make sure BOTH service accounts have all required roles (see Step 5)

#### Workload Identity Federation Errors

**Problem:** `invalid_target` error

**Solution:** 
1. Verify pool exists: `gcloud iam workload-identity-pools describe github-pool --location=global`
2. Verify provider exists: `gcloud iam workload-identity-pools providers describe github-provider --location=global --workload-identity-pool=github-pool`
3. Recreate if needed (see Step 6)

#### gcloud Command Not Found (Windows)

**Solution:**
```powershell
$env:Path += ";C:\Users\$env:USERNAME\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin"
```

Or use "Google Cloud SDK Shell" from Start Menu

#### Build Fails at Docker Step

**Problem:** Cloud Build can't push to Artifact Registry

**Solution:** Add `Artifact Registry Writer` role to Cloud Build service account

#### Cloud Run Deployment Fails

**Problem:** Permission to deploy denied

**Solution:** Add `Cloud Run Developer` role to Cloud Build service account

---

## 🧪 Testing & Verification

### Verify Deployment

```bash
# Get Cloud Run service URL
gcloud run services describe gcp-devops-demo \
  --region=asia-east1 \
  --format="value(status.url)"

# Test all endpoints
curl https://your-service-url/
curl https://your-service-url/health
curl https://your-service-url/info
```

### Check Infrastructure

```bash
# List Cloud Run services
gcloud run services list --region=asia-east1

# List Artifact Registry repositories
gcloud artifacts repositories list --location=asia-east1

# Verify IAM permissions
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --format="table(bindings.role)"
```

### Test CI/CD Pipeline

```bash
# Make a small change
echo "# Test" >> test.txt

# Commit and push
git add test.txt
git commit -m "Test: Trigger deployment"
git push origin main

# Watch deployment
# Go to: https://github.com/YOUR-USERNAME/gcp-devops-demo/actions
```

---

## 🔍 Monitoring & Debugging

### View Cloud Build Logs

```bash
# List recent builds
gcloud builds list --limit=10

# View specific build logs
gcloud builds log BUILD_ID

# Or view in console
# https://console.cloud.google.com/cloud-build/builds
```

### View Cloud Run Logs

```bash
# Stream logs
gcloud run services logs read gcp-devops-demo \
  --region=asia-east1 \
  --limit=50

# Or view in console
# https://console.cloud.google.com/run
```

### Debug Common Issues

**Build fails:**
```bash
# Check Cloud Build logs
gcloud builds list --limit=1
gcloud builds log $(gcloud builds list --limit=1 --format="value(id)")
```

**Deployment fails:**
```bash
# Check Cloud Run logs
gcloud run services logs read gcp-devops-demo --region=asia-east1
```

**Permission errors:**
```bash
# Verify IAM roles
gcloud projects get-iam-policy $PROJECT_ID
```

---

## 🧹 Cleanup

To avoid charges, destroy all resources:

```powershell
# Destroy infrastructure
cd terraform
terraform destroy
# Type: yes

# Delete Workload Identity Pool (optional)
gcloud iam workload-identity-pools delete github-pool --location=global

# Delete service account (optional)
gcloud iam service-accounts delete github-actions-sa@your-project-id.iam.gserviceaccount.com
```

---

## 📊 Complete Permissions Summary (Least Privilege)

**All permissions are automatically granted by Terraform via `terraform/iam.tf`**

### github-actions-sa Service Account:
1. Cloud Build Service Account (`roles/cloudbuild.builds.editor`) - Submit builds
2. Cloud Run Developer (`roles/run.developer`) - Deploy services
3. Service Account User (`roles/iam.serviceAccountUser`) - Impersonate service accounts
4. Service Usage Consumer (`roles/serviceusage.serviceUsageConsumer`) - Use GCP APIs
5. Storage Object User (`roles/storage.objectUser`) - Read/write Cloud Storage objects
6. Artifact Registry Writer (`roles/artifactregistry.writer`) - Push Docker images

### [PROJECT_NUMBER]-compute@developer.gserviceaccount.com (Cloud Build SA):
1. Storage Object User (`roles/storage.objectUser`) - Upload build artifacts
2. Logs Writer (`roles/logging.logWriter`) - Write build logs
3. Artifact Registry Writer (`roles/artifactregistry.writer`) - Push Docker images
4. Cloud Run Developer (`roles/run.developer`) - Deploy to Cloud Run
5. Service Account User (`roles/iam.serviceAccountUser`) - Impersonate service accounts

**Security Notes:**
- ✅ Follows **Principle of Least Privilege**
- ✅ No "Admin" roles (only Developer/Writer/User)
- ✅ Can't delete buckets or repositories
- ✅ Can't manage IAM policies
- ✅ Limited blast radius if compromised

**To customize permissions:** Edit `terraform/iam.tf` and run `terraform apply`

---

## 🎓 What You've Learned

After completing this project, you've learned:
- ✅ Infrastructure as Code with Terraform (including IAM!)
- ✅ **Principle of Least Privilege** for security
- ✅ Docker containerization
- ✅ CI/CD with GitHub Actions
- ✅ Workload Identity Federation (keyless authentication)
- ✅ GCP IAM managed via Terraform
- ✅ Cloud Run serverless deployment
- ✅ Artifact Registry for container images
- ✅ Cloud Build for automated builds
- ✅ **Automated IAM management** (no manual clicking!)

---

## 💰 Cost Management

**Expected costs for learning:** $0-5/month
- Cloud Run scales to zero (no charges when idle)
- Free tier: 2 million requests/month
- Artifact Registry: ~$0.10/GB/month

**To minimize costs:**
- Run `terraform destroy` when done
- Delete unused images from Artifact Registry
- Set up billing alerts

---

## 📚 Additional Resources

- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

**🎉 Congratulations!** You've built a production-ready CI/CD pipeline!

**Project by:** GCP DevOps Learning  
**Last Updated:** January 2026  
**Version:** 2.0.0 (Updated with correct permissions)