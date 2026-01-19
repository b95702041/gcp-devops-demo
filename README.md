# GCP DevOps Demo Project

A complete learning project demonstrating modern DevOps practices on Google Cloud Platform (GCP), including CI/CD pipelines, containerization, and Infrastructure as Code.

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Setup Instructions](#setup-instructions)
- [Local Development](#local-development)
- [Deployment Process](#deployment-process)
- [Verification](#verification)
- [Cleanup](#cleanup)
- [Troubleshooting](#troubleshooting)
- [Learning Resources](#learning-resources)

## 🎯 Project Overview

This project demonstrates a complete DevOps workflow for deploying a Python Flask application to Google Cloud Run using:

- **Application**: Simple Flask REST API with health check endpoints
- **Containerization**: Docker with multi-stage builds
- **Infrastructure as Code**: Terraform for GCP resource management
- **CI/CD**: GitHub Actions + Google Cloud Build
- **Container Registry**: Google Artifact Registry
- **Compute**: Google Cloud Run (serverless containers)
- **Region**: asia-east1 (Taiwan)

### Key Features

- ✅ Automated CI/CD pipeline
- ✅ Infrastructure as Code (reproducible deployments)
- ✅ Containerized application
- ✅ Serverless architecture (scales to zero)
- ✅ Security best practices (non-root containers, least privilege)
- ✅ Cost-effective (pay only for actual usage)

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub Repository                        │
│                                                                   │
│  ┌──────────┐  ┌────────────┐  ┌──────────┐  ┌──────────────┐ │
│  │  Flask   │  │ Dockerfile │  │ Terraform│  │  CloudBuild  │ │
│  │   App    │  │            │  │   IaC    │  │    Config    │ │
│  └──────────┘  └────────────┘  └──────────┘  └──────────────┘ │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Push to main branch
                         ▼
              ┌──────────────────────┐
              │   GitHub Actions     │
              │  (CI/CD Trigger)     │
              └──────────┬───────────┘
                         │
                         │ Authenticate & Submit Build
                         ▼
              ┌──────────────────────┐
              │   Cloud Build        │
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
  └──────────────┘ └─────────┘  └──────────────┘
                                        │
                                        │ HTTPS
                                        ▼
                                 ┌──────────────┐
                                 │    Public    │
                                 │     API      │
                                 └──────────────┘
```

### API Endpoints

- `GET /` - Welcome message with timestamp
- `GET /health` - Health check endpoint
- `GET /info` - Application metadata

## 📦 Prerequisites

Before starting, ensure you have the following:

### 1. GCP Account

- Create a GCP account: https://cloud.google.com/
- You'll need billing enabled (free tier includes $300 credit for new users)

### 2. Required Tools

Install these tools on your local machine:

```bash
# Google Cloud SDK (gcloud CLI)
# Install: https://cloud.google.com/sdk/docs/install

# Terraform
# Install: https://developer.hashicorp.com/terraform/downloads

# Docker (optional, for local testing)
# Install: https://docs.docker.com/get-docker/

# Git
# Install: https://git-scm.com/downloads

# GitHub account
# Create: https://github.com/join
```

### 3. Verify Installations

```bash
gcloud --version
terraform --version
docker --version
git --version
```

## 📁 Project Structure

```
gcp-devops-demo/
├── app/                          # Application code
│   ├── main.py                   # Flask application
│   ├── requirements.txt          # Python dependencies
│   └── Dockerfile                # Container configuration
├── terraform/                    # Infrastructure as Code
│   ├── main.tf                   # Main Terraform configuration
│   ├── variables.tf              # Variable definitions
│   ├── outputs.tf                # Output values
│   └── terraform.tfvars.example  # Example variables file
├── .github/
│   └── workflows/
│       └── deploy.yaml           # GitHub Actions CI/CD pipeline
├── cloudbuild.yaml               # Cloud Build configuration
├── .gitignore                    # Git ignore rules
└── README.md                     # This file
```

## 🚀 Setup Instructions

Follow these steps carefully to set up the project:

### Step 1: Create and Configure GCP Project

```bash
# 1. Create a new GCP project (or use existing)
gcloud projects create YOUR-PROJECT-ID --name="GCP DevOps Demo"

# 2. Set the project as default
gcloud config set project YOUR-PROJECT-ID

# 3. Enable billing for the project
# Go to: https://console.cloud.google.com/billing
# Link your project to a billing account

# 4. Verify your project is set correctly
gcloud config get-value project
```

### Step 2: Install and Authenticate gcloud CLI

```bash
# Initialize gcloud
gcloud init

# Authenticate your account
gcloud auth login

# Set application default credentials (for Terraform)
gcloud auth application-default login
```

### Step 3: Create Service Account for CI/CD

The service account needs permissions to manage Cloud Build, Cloud Run, and Artifact Registry:

```bash
# Set your project ID
export PROJECT_ID="YOUR-PROJECT-ID"

# Create service account
gcloud iam service-accounts create github-actions-sa \
    --display-name="GitHub Actions Service Account" \
    --project=$PROJECT_ID

# Grant required roles to the service account
# Cloud Build Editor - Manage Cloud Build jobs
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/cloudbuild.builds.editor"

# Cloud Run Admin - Deploy and manage Cloud Run services
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/run.admin"

# Artifact Registry Administrator - Push Docker images
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.admin"

# Service Account User - Act as service accounts
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

# Storage Admin - Access Cloud Build artifacts
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# Download service account key (JSON file)
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com

# ⚠️ IMPORTANT: Keep this file secure! It provides full access to your GCP project
echo "Service account key saved to: github-actions-key.json"
```

### Step 4: Create GitHub Repository and Add Secrets

```bash
# 1. Create a new repository on GitHub
# Go to: https://github.com/new
# Name it: gcp-devops-demo

# 2. Add GitHub Secrets (required for CI/CD)
# Go to: https://github.com/YOUR-USERNAME/gcp-devops-demo/settings/secrets/actions
# Click "New repository secret" and add:

# Secret 1: GCP_PROJECT_ID
#   Value: YOUR-PROJECT-ID

# Secret 2: GCP_SA_KEY
#   Value: (entire contents of github-actions-key.json file)
#   Copy the full JSON content including { } braces
```

### Step 5: Initialize Local Repository

```bash
# Clone this repository or create a new one
git clone https://github.com/YOUR-USERNAME/gcp-devops-demo.git
cd gcp-devops-demo

# Or if starting fresh:
git init
git remote add origin https://github.com/YOUR-USERNAME/gcp-devops-demo.git
```

### Step 6: Configure Terraform

```bash
# Navigate to terraform directory
cd terraform

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your project ID
# Replace "your-gcp-project-id" with your actual project ID
nano terraform.tfvars  # or use your preferred editor

# The file should look like:
# project_id = "YOUR-PROJECT-ID"
# region = "asia-east1"
# app_name = "gcp-devops-demo"
```

### Step 7: Deploy Infrastructure with Terraform

```bash
# Still in terraform/ directory

# Initialize Terraform (downloads providers)
terraform init

# Preview changes (what will be created)
terraform plan

# Create the infrastructure
terraform apply

# Review the planned changes and type "yes" to confirm

# Save the outputs for later use
terraform output
```

Expected output:
```
cloud_run_url = "https://gcp-devops-demo-xxxxx-uc.a.run.app"
artifact_registry_repository = "projects/YOUR-PROJECT/locations/asia-east1/repositories/gcp-devops-demo-repo"
```

### Step 8: Push Code to GitHub (Triggers First Deployment)

```bash
# Return to project root
cd ..

# Stage all files
git add .

# Commit changes
git commit -m "Initial commit: Complete GCP DevOps setup"

# Push to GitHub (this triggers the CI/CD pipeline!)
git push -u origin main
```

### Step 9: Monitor Deployment

```bash
# Watch GitHub Actions workflow
# Go to: https://github.com/YOUR-USERNAME/gcp-devops-demo/actions

# Monitor Cloud Build logs (alternative)
gcloud builds list --limit=5

# Get build details
gcloud builds log BUILD_ID --stream
```

## 💻 Local Development

### Run Flask App Locally

```bash
# Navigate to app directory
cd app

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the application
export PORT=8080
export VERSION=1.0.0
export ENVIRONMENT=development
python main.py

# Test endpoints
curl http://localhost:8080/
curl http://localhost:8080/health
curl http://localhost:8080/info
```

### Build and Run Docker Container Locally

```bash
# Build the Docker image
cd app
docker build -t gcp-devops-demo:local .

# Run the container
docker run -p 8080:8080 \
  -e VERSION=1.0.0 \
  -e ENVIRONMENT=local \
  gcp-devops-demo:local

# Test the containerized app
curl http://localhost:8080/health
```

### Test Changes Before Deploying

```bash
# 1. Make changes to app/main.py
# 2. Test locally (see above)
# 3. Commit and push to trigger deployment
git add .
git commit -m "Update: description of changes"
git push origin main
```

## 🔄 Deployment Process

The automated deployment follows these steps:

1. **Trigger**: Code pushed to `main` branch
2. **GitHub Actions**: 
   - Authenticates to GCP
   - Submits build to Cloud Build
3. **Cloud Build**:
   - Builds Docker image
   - Pushes to Artifact Registry
   - Deploys to Cloud Run
4. **Cloud Run**: 
   - Pulls new image
   - Creates new revision
   - Routes traffic to new revision

### Manual Deployment (Alternative)

If you want to deploy manually without GitHub Actions:

```bash
# Submit build directly to Cloud Build
gcloud builds submit \
  --config=cloudbuild.yaml \
  --substitutions=_REGION=asia-east1,_APP_NAME=gcp-devops-demo,SHORT_SHA=$(git rev-parse --short HEAD)
```

## ✅ Verification

### Test the Deployed Application

```bash
# Get your Cloud Run URL
SERVICE_URL=$(gcloud run services describe gcp-devops-demo \
  --region=asia-east1 \
  --format='value(status.url)')

echo "Service URL: $SERVICE_URL"

# Test health endpoint
curl $SERVICE_URL/health

# Test info endpoint
curl $SERVICE_URL/info

# Test welcome endpoint
curl $SERVICE_URL/
```

### View Logs

```bash
# View Cloud Run logs
gcloud run services logs read gcp-devops-demo \
  --region=asia-east1 \
  --limit=50

# Stream live logs
gcloud run services logs tail gcp-devops-demo \
  --region=asia-east1
```

### Check Cloud Build History

```bash
# List recent builds
gcloud builds list --limit=10

# View specific build
gcloud builds describe BUILD_ID
```

## 🧹 Cleanup

To avoid ongoing charges, destroy all resources when done:

```bash
# Option 1: Destroy infrastructure with Terraform (Recommended)
cd terraform
terraform destroy
# Type "yes" to confirm

# Option 2: Delete individual resources manually
gcloud run services delete gcp-devops-demo --region=asia-east1
gcloud artifacts repositories delete gcp-devops-demo-repo --location=asia-east1

# Delete service account
gcloud iam service-accounts delete github-actions-sa@YOUR-PROJECT-ID.iam.gserviceaccount.com

# Delete the entire project (nuclear option)
gcloud projects delete YOUR-PROJECT-ID
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. "APIs not enabled" Error

**Problem**: Build fails with "API not enabled" error

**Solution**:
```bash
# Manually enable required APIs
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

#### 2. Permission Denied Errors

**Problem**: Service account doesn't have sufficient permissions

**Solution**:
```bash
# Re-run the service account permission commands from Step 3
# Make sure all roles are granted
```

#### 3. GitHub Actions Fails to Authenticate

**Problem**: "Invalid service account key" error

**Solution**:
- Verify `GCP_SA_KEY` secret contains the complete JSON file content
- Ensure no extra spaces or newlines were added when copying
- Recreate the service account key if needed

#### 4. Terraform Apply Fails

**Problem**: Terraform can't create resources

**Solution**:
```bash
# Ensure you're authenticated
gcloud auth application-default login

# Verify project is set
gcloud config get-value project

# Check if APIs are enabled
gcloud services list --enabled
```

#### 5. Cloud Run Service Returns 404

**Problem**: Service deployed but endpoints return 404

**Solution**:
```bash
# Check if the correct image is deployed
gcloud run services describe gcp-devops-demo --region=asia-east1

# View logs for errors
gcloud run services logs read gcp-devops-demo --region=asia-east1

# Check container health
gcloud run revisions describe REVISION_NAME --region=asia-east1
```

#### 6. Docker Build Fails Locally

**Problem**: Can't build Docker image on local machine

**Solution**:
```bash
# Ensure Docker daemon is running
docker ps

# Build with verbose output
docker build --progress=plain -t gcp-devops-demo:local ./app
```

#### 7. High Cloud Run Costs

**Problem**: Unexpected charges

**Solution**:
- Verify min-instances is set to 0 (scale to zero)
- Check for memory/CPU over-allocation
- Review request timeout settings
- Monitor in Cloud Console: https://console.cloud.google.com/run

### Getting Help

If you encounter issues not covered here:

1. **Check Cloud Build Logs**: 
   ```bash
   gcloud builds list
   gcloud builds log BUILD_ID
   ```

2. **Review Cloud Run Logs**:
   ```bash
   gcloud run services logs read gcp-devops-demo --region=asia-east1
   ```

3. **Consult GCP Documentation**:
   - Cloud Run: https://cloud.google.com/run/docs
   - Cloud Build: https://cloud.google.com/build/docs
   - Terraform Google Provider: https://registry.terraform.io/providers/hashicorp/google/latest/docs

## 📚 Learning Resources

### Official Documentation

- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Google Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Google Artifact Registry Documentation](https://cloud.google.com/artifact-registry/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

### Recommended Learning Paths

1. **Docker Basics**: Learn containerization fundamentals
2. **Terraform Fundamentals**: Understand Infrastructure as Code
3. **CI/CD Concepts**: Learn continuous integration and deployment
4. **GCP Cloud Run**: Serverless container platform
5. **DevOps Best Practices**: Security, monitoring, automation

### Next Steps

After completing this project, consider:

- ✨ Add a Cloud SQL database
- ✨ Implement Cloud Monitoring and alerting
- ✨ Add Cloud Armor for DDoS protection
- ✨ Set up custom domain with Cloud Load Balancing
- ✨ Implement blue/green deployments
- ✨ Add unit and integration tests
- ✨ Use Workload Identity Federation instead of service account keys

## 📝 License

This project is for educational purposes. Feel free to use and modify as needed for learning.

## 🤝 Contributing

This is a learning project! Feel free to:
- Report issues
- Suggest improvements
- Share your learnings

---

**Happy Learning! 🚀**

If you found this helpful, please star the repository and share with others learning DevOps!
