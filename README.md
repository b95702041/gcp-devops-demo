# GCP DevOps Demo - Complete Setup Guide (Updated with Correct Permissions)

A complete hands-on learning project for Google Cloud Platform DevOps, featuring CI/CD pipelines, Docker containerization, Infrastructure as Code with Terraform, and serverless deployment on Cloud Run.

**⚠️ IMPORTANT: This guide includes ALL required permissions discovered through testing.**

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Prerequisites](#prerequisites)
3. [Complete Setup Guide](#complete-setup-guide)
4. [Troubleshooting](#troubleshooting)
5. [Cleanup](#cleanup)

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

### Step 5: Run Initial Setup Script

**This step creates the service account and Workload Identity Federation.**

```powershell
# Edit the setup script first with your details
notepad setup-initial.ps1

# Update these variables:
# $PROJECT_ID = "your-project-id"
# $GITHUB_USERNAME = "your-github-username"
# $GITHUB_REPO = "gcp-devops-demo"

# Run the setup script
.\setup-initial.ps1
```

This script will:
- ✅ Create `github-actions-sa` service account
- ✅ Create Workload Identity Federation pool and provider
- ✅ Grant WIF access
- ✅ Display the values for GitHub secrets

**Note:** IAM permissions are NOT granted yet - Terraform will handle that in Step 7!

### Step 6: Add GitHub Secrets

The setup script from Step 5 displayed these values. Add them to GitHub:

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