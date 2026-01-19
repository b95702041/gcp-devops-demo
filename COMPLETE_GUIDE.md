# GCP DevOps Demo - Complete Setup Guide

A complete hands-on learning project for Google Cloud Platform DevOps, featuring CI/CD pipelines, Docker containerization, Infrastructure as Code with Terraform, and serverless deployment on Cloud Run.

---

## 📑 Table of Contents

1. [Project Overview](#project-overview)
2. [What You'll Learn](#what-youll-learn)
3. [Architecture](#architecture)
4. [Project Structure](#project-structure)
5. [Prerequisites](#prerequisites)
6. [Complete Setup Guide](#complete-setup-guide)
7. [GitHub Setup](#github-setup)
8. [Local Development](#local-development)
9. [Deployment Process](#deployment-process)
10. [Testing & Verification](#testing--verification)
11. [Making Changes](#making-changes)
12. [Monitoring & Debugging](#monitoring--debugging)
13. [Cleanup](#cleanup)
14. [Troubleshooting](#troubleshooting)
15. [Command Reference](#command-reference)
16. [Cost Management](#cost-management)
17. [Next Steps](#next-steps)

---

## 🎯 Project Overview

This project demonstrates a complete modern DevOps workflow by deploying a Python Flask API to Google Cloud Run with automated CI/CD.

### Key Technologies

- **Application**: Python Flask REST API
- **Containerization**: Docker with multi-stage builds
- **Infrastructure as Code**: Terraform
- **CI/CD**: GitHub Actions + Google Cloud Build
- **Container Registry**: Google Artifact Registry
- **Compute**: Google Cloud Run (serverless)
- **Region**: asia-east1 (Taiwan)

### What Gets Deployed

A simple Flask API with three endpoints:
- `GET /` - Welcome message with timestamp
- `GET /health` - Health check endpoint
- `GET /info` - Application metadata

---

## 📚 What You'll Learn

After completing this project, you'll understand:

✅ **Docker**: Building production-ready container images with multi-stage builds  
✅ **Terraform**: Managing cloud infrastructure as code  
✅ **CI/CD**: Automating build, test, and deployment pipelines  
✅ **Cloud Run**: Deploying serverless containerized applications  
✅ **Git/GitHub**: Version control and GitHub Actions workflows  
✅ **GCP Services**: Artifact Registry, Cloud Build, IAM, and more  
✅ **Security**: Service accounts, least privilege, non-root containers  
✅ **DevOps Best Practices**: Automated deployments, infrastructure as code, monitoring  

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

### How It Works

1. You push code to GitHub `main` branch
2. GitHub Actions triggers automatically
3. Cloud Build builds Docker image
4. Image pushed to Artifact Registry
5. Cloud Run deploys new version
6. Application is live and accessible via HTTPS

---

## 📁 Project Structure

```
gcp-devops-demo/
├── app/                          # Application code
│   ├── main.py                   # Flask API with endpoints
│   ├── requirements.txt          # Python dependencies
│   └── Dockerfile                # Container build instructions
├── terraform/                    # Infrastructure as Code
│   ├── main.tf                   # GCP resources definition
│   ├── variables.tf              # Configurable variables
│   ├── outputs.tf                # Important output values
│   └── terraform.tfvars.example  # Example configuration
├── .github/
│   └── workflows/
│       └── deploy.yaml           # CI/CD pipeline definition
├── cloudbuild.yaml               # Cloud Build steps
├── .gitignore                    # Files to exclude from Git
└── README.md                     # This file
```

---

## 📦 Prerequisites

### Required Accounts

1. **Google Cloud Platform Account**
   - Sign up: https://cloud.google.com/
   - Free tier includes $300 credit for new users
   - Billing must be enabled

2. **GitHub Account**
   - Sign up: https://github.com/join
   - Free account is sufficient

### Required Tools

Install these on your local machine:

#### 1. Google Cloud SDK (gcloud CLI)
```bash
# macOS (using Homebrew)
brew install google-cloud-sdk

# Linux
curl https://sdk.cloud.google.com | bash

# Windows
# Download installer from: https://cloud.google.com/sdk/docs/install

# Verify installation
gcloud --version
```

#### 2. Terraform
```bash
# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Windows (using Chocolatey)
choco install terraform

# Verify installation
terraform --version
```

#### 3. Docker (Optional - for local testing)
```bash
# macOS/Windows: Download Docker Desktop
# https://www.docker.com/products/docker-desktop

# Linux
sudo apt-get update
sudo apt-get install docker.io

# Verify installation
docker --version
```

#### 4. Git
```bash
# macOS
brew install git

# Linux
sudo apt-get install git

# Windows
# Download from: https://git-scm.com/download/win

# Verify installation
git --version

# Configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

## 🚀 Complete Setup Guide

Follow these steps in order. Each step is essential!

### Step 1: Create GCP Project

```bash
# Set your desired project ID
export PROJECT_ID="your-unique-project-id"

# Create the project
gcloud projects create $PROJECT_ID --name="GCP DevOps Demo"

# Set as default project
gcloud config set project $PROJECT_ID

# Verify
gcloud config get-value project
```

**Enable Billing:**
1. Go to: https://console.cloud.google.com/billing
2. Link your project to a billing account
3. Verify billing is enabled

### Step 2: Authenticate gcloud CLI

```bash
# Login to your Google account
gcloud auth login

# Set application default credentials (for Terraform)
gcloud auth application-default login

# Verify authentication
gcloud auth list
```

### Step 3: Create Service Account for CI/CD

This service account will be used by GitHub Actions to deploy your application.

```bash
# Create service account
gcloud iam service-accounts create github-actions-sa \
    --display-name="GitHub Actions Service Account" \
    --project=$PROJECT_ID

# Grant Cloud Build Editor role
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/cloudbuild.builds.editor"

# Grant Cloud Run Admin role
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/run.admin"

# Grant Artifact Registry Admin role
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.admin"

# Grant Service Account User role
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

# Grant Storage Admin role
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# Create and download service account key
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com

echo "✅ Service account key saved to: github-actions-key.json"
echo "⚠️  Keep this file secure! It provides access to your GCP project"
```

### Step 4: Configure Terraform

```bash
# Navigate to terraform directory
cd terraform

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your project ID
# Use your preferred text editor (nano, vim, vscode, etc.)
nano terraform.tfvars

# Update the file to look like this:
# project_id = "your-unique-project-id"
# region = "asia-east1"
# app_name = "gcp-devops-demo"
```

### Step 5: Deploy Infrastructure with Terraform

```bash
# Still in terraform/ directory

# Initialize Terraform (downloads providers)
terraform init

# Validate configuration
terraform validate

# Preview what will be created
terraform plan

# Create the infrastructure
terraform apply

# Type "yes" when prompted

# Wait for completion (takes 2-5 minutes)
# Terraform will create:
# - Artifact Registry repository
# - Cloud Run service
# - Enable required APIs
# - Set up IAM policies
```

**Save the outputs:**
```bash
# Display outputs
terraform output

# Save Cloud Run URL
export CLOUD_RUN_URL=$(terraform output -raw cloud_run_url)
echo "Cloud Run URL: $CLOUD_RUN_URL"
```

---

## 🐙 GitHub Setup

### Step 1: Create GitHub Repository

1. **Go to GitHub**: https://github.com/new

2. **Configure repository**:
   - Repository name: `gcp-devops-demo`
   - Description: `GCP DevOps learning project with CI/CD`
   - Visibility: Choose Public or Private
   
   **⚠️ IMPORTANT**: Do NOT check these boxes:
   - ☐ Add a README file
   - ☐ Add .gitignore
   - ☐ Choose a license

3. **Click "Create repository"**

### Step 2: Create Personal Access Token

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Configure:
   - Note: `GCP DevOps Demo`
   - Expiration: `90 days` (or longer)
   - Select scopes:
     - ✅ `repo` (Full control of private repositories)
     - ✅ `workflow` (Update GitHub Action workflows)
4. Click "Generate token"
5. **COPY THE TOKEN** (starts with `ghp_...`)
6. Save it securely - you won't see it again!

### Step 3: Push Code to GitHub

```bash
# Return to project root
cd ..  # (if you're still in terraform/)

# Verify you're in the project root
ls -la
# You should see: app/, terraform/, .github/, README.md

# Initialize Git repository
git init

# Add GitHub as remote (replace YOUR-USERNAME)
git remote add origin https://github.com/YOUR-USERNAME/gcp-devops-demo.git

# Stage all files
git add .

# Check what will be committed
git status

# Create first commit
git commit -m "Initial commit: Complete GCP DevOps project setup"

# Rename branch to main
git branch -M main

# Push to GitHub
git push -u origin main

# When prompted:
# Username: your-github-username
# Password: your-personal-access-token (the ghp_... token you created)
```

### Step 4: Add GitHub Secrets

These secrets allow GitHub Actions to deploy to GCP:

1. **Navigate to repository secrets**:
   - Go to: `https://github.com/YOUR-USERNAME/gcp-devops-demo/settings/secrets/actions`

2. **Add GCP_PROJECT_ID secret**:
   - Click "New repository secret"
   - Name: `GCP_PROJECT_ID`
   - Value: Your GCP project ID (e.g., `my-devops-project-123`)
   - Click "Add secret"

3. **Add GCP_SA_KEY secret**:
   - Click "New repository secret"
   - Name: `GCP_SA_KEY`
   - Value: Complete contents of `github-actions-key.json`
   
   **To copy the file contents:**
   ```bash
   # macOS
   cat github-actions-key.json | pbcopy
   
   # Linux
   cat github-actions-key.json | xclip -selection clipboard
   
   # Windows
   type github-actions-key.json | clip
   
   # Or open in text editor and copy everything
   ```
   
   - Paste the entire JSON (including `{` and `}`)
   - Click "Add secret"

4. **Verify secrets are added**:
   - You should see:
     - ✅ `GCP_PROJECT_ID`
     - ✅ `GCP_SA_KEY`

### Step 5: Trigger First Deployment

The push to GitHub already triggered the deployment! Watch it:

1. **Go to Actions tab**:
   - `https://github.com/YOUR-USERNAME/gcp-devops-demo/actions`

2. **Click on the running workflow**:
   - You'll see "Deploy to Google Cloud Run"
   - Status will show as yellow (running) or green (completed)

3. **Click on the workflow** to see detailed logs

4. **Wait for completion** (typically 5-10 minutes)

---

## 💻 Local Development

### Run Flask App Locally

```bash
# Navigate to app directory
cd app

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# macOS/Linux:
source venv/bin/activate

# Windows:
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export PORT=8080
export VERSION=1.0.0
export ENVIRONMENT=development

# Run the application
python main.py

# In another terminal, test the endpoints:
curl http://localhost:8080/
curl http://localhost:8080/health
curl http://localhost:8080/info

# Stop the app: Ctrl+C
# Deactivate virtual environment:
deactivate
```

### Build and Test Docker Container Locally

```bash
# Build the Docker image
cd app
docker build -t gcp-devops-demo:local .

# Run the container
docker run -p 8080:8080 \
  -e VERSION=1.0.0 \
  -e ENVIRONMENT=local \
  --name devops-demo \
  gcp-devops-demo:local

# In another terminal, test the containerized app:
curl http://localhost:8080/health
curl http://localhost:8080/info

# View logs
docker logs devops-demo

# Stop and remove container
docker stop devops-demo
docker rm devops-demo
```

---

## 🔄 Deployment Process

### Automated Deployment Flow

Every push to the `main` branch triggers:

```
1. GitHub Actions workflow starts
   ├─ Authenticates to GCP
   ├─ Sets up gcloud CLI
   └─ Submits build to Cloud Build

2. Cloud Build executes
   ├─ Builds Docker image
   ├─ Tags with commit SHA and 'latest'
   ├─ Pushes to Artifact Registry
   └─ Deploys to Cloud Run

3. Cloud Run updates
   ├─ Pulls new image
   ├─ Creates new revision
   ├─ Routes 100% traffic to new revision
   └─ Scales containers as needed
```

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

## ✅ Testing & Verification

### Get Your Service URL

```bash
# Using gcloud
SERVICE_URL=$(gcloud run services describe gcp-devops-demo \
  --region=asia-east1 \
  --format='value(status.url)')

echo "Service URL: $SERVICE_URL"

# Or using Terraform output
cd terraform
terraform output cloud_run_url
```

### Test All Endpoints

```bash
# Test health endpoint
curl $SERVICE_URL/health

# Expected response:
# {"status":"healthy","version":"1.0.0"}

# Test info endpoint
curl $SERVICE_URL/info

# Test welcome endpoint
curl $SERVICE_URL/

# Pretty print JSON (if you have jq installed)
curl $SERVICE_URL/info | jq
```

### Test in Browser

Simply open these URLs in your browser:
- `https://your-service-url/`
- `https://your-service-url/health`
- `https://your-service-url/info`

---

## 🔧 Making Changes

### Development Workflow

```bash
# 1. Make changes to your code
# Example: Edit app/main.py

# 2. Test locally (optional but recommended)
cd app
python main.py
# Or test with Docker

# 3. Check what changed
git status
git diff

# 4. Stage changes
git add .
# Or stage specific files:
git add app/main.py

# 5. Commit with descriptive message
git commit -m "Update: Added new endpoint for user status"

# 6. Push to GitHub (triggers automatic deployment)
git push origin main

# 7. Monitor deployment
# https://github.com/YOUR-USERNAME/gcp-devops-demo/actions
```

### Example: Add a New Endpoint

Edit `app/main.py` and add:

```python
@app.route('/status')
def status():
    """New status endpoint"""
    return jsonify({
        'app_status': 'running',
        'uptime': 'healthy',
        'timestamp': datetime.utcnow().isoformat()
    })
```

Then deploy:
```bash
git add app/main.py
git commit -m "Add /status endpoint"
git push origin main
```

---

## 📊 Monitoring & Debugging

### View Cloud Run Logs

```bash
# View recent logs
gcloud run services logs read gcp-devops-demo \
  --region=asia-east1 \
  --limit=50

# Stream live logs
gcloud run services logs tail gcp-devops-demo \
  --region=asia-east1

# Filter logs
gcloud run services logs read gcp-devops-demo \
  --region=asia-east1 \
  --filter='severity>=ERROR'
```

### View Cloud Build History

```bash
# List recent builds
gcloud builds list --limit=10

# Get build details
gcloud builds describe BUILD_ID

# Stream build logs
gcloud builds log BUILD_ID --stream
```

### View Service Details

```bash
# Describe Cloud Run service
gcloud run services describe gcp-devops-demo \
  --region=asia-east1

# List all revisions
gcloud run revisions list \
  --service=gcp-devops-demo \
  --region=asia-east1

# View specific revision
gcloud run revisions describe REVISION_NAME \
  --region=asia-east1
```

### GCP Console (Web UI)

- **Cloud Run Dashboard**: https://console.cloud.google.com/run
- **Cloud Build History**: https://console.cloud.google.com/cloud-build
- **Artifact Registry**: https://console.cloud.google.com/artifacts
- **Logs Explorer**: https://console.cloud.google.com/logs

---

## 🧹 Cleanup

To avoid ongoing charges, destroy all resources when done learning:

### Option 1: Terraform Destroy (Recommended)

```bash
# Navigate to terraform directory
cd terraform

# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Type "yes" when prompted

# This removes:
# - Cloud Run service
# - Artifact Registry repository
# - All images
```

### Option 2: Manual Cleanup

```bash
# Delete Cloud Run service
gcloud run services delete gcp-devops-demo \
  --region=asia-east1 \
  --quiet

# Delete Artifact Registry repository
gcloud artifacts repositories delete gcp-devops-demo-repo \
  --location=asia-east1 \
  --quiet

# Delete service account
gcloud iam service-accounts delete \
  github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --quiet
```

### Option 3: Delete Entire Project (Nuclear Option)

```bash
# Delete the entire GCP project
gcloud projects delete $PROJECT_ID

# This removes EVERYTHING in the project
```

### Clean Up Local Files

```bash
# Remove service account key (important for security!)
rm -f github-actions-key.json

# Remove Terraform state (optional)
cd terraform
rm -rf .terraform/
rm -f terraform.tfstate*
```

---

## 🔧 Troubleshooting

### Common Issues & Solutions

#### 1. API Not Enabled

**Error**: `"API [servicename] not enabled on project"`

**Solution**:
```bash
# Enable required APIs manually
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

#### 2. Permission Denied

**Error**: `"Permission denied"` or `"Caller does not have permission"`

**Solution**:
- Verify service account has all required roles
- Re-run the service account permission commands from Step 3
- Check billing is enabled

#### 3. GitHub Actions Authentication Failed

**Error**: `"Invalid service account key"`

**Solution**:
- Verify `GCP_SA_KEY` secret contains complete JSON
- Ensure no extra spaces or newlines
- Recreate service account key if needed:
```bash
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com
```

#### 4. Git Push Authentication Failed

**Error**: `"Authentication failed"` when pushing to GitHub

**Solution**:
- Use Personal Access Token (NOT your GitHub password)
- Create token at: https://github.com/settings/tokens
- Make sure token has `repo` and `workflow` scopes

#### 5. Terraform Apply Fails

**Error**: Various Terraform errors

**Solutions**:
```bash
# Ensure authenticated
gcloud auth application-default login

# Verify project is set
gcloud config get-value project

# Check terraform.tfvars has correct project_id
cat terraform/terraform.tfvars

# Try re-initializing
cd terraform
rm -rf .terraform/
terraform init
```

#### 6. Docker Build Fails Locally

**Error**: Docker build errors

**Solution**:
```bash
# Ensure Docker is running
docker ps

# Build with verbose output
docker build --no-cache --progress=plain -t gcp-devops-demo:local ./app

# Check Dockerfile syntax
cd app
cat Dockerfile
```

#### 7. Cloud Run Returns 404

**Error**: Service deployed but endpoints return 404

**Solution**:
```bash
# Check if correct image is deployed
gcloud run services describe gcp-devops-demo --region=asia-east1

# View container logs for errors
gcloud run services logs read gcp-devops-demo --region=asia-east1

# Check health endpoint
curl -v SERVICE_URL/health
```

#### 8. High Unexpected Costs

**Problem**: Unexpected charges

**Solutions**:
- Verify min-instances is 0 (scale to zero)
```bash
gcloud run services describe gcp-devops-demo --region=asia-east1 \
  --format='value(spec.template.metadata.annotations.autoscaling\.knative\.dev/minScale)'
```
- Set up billing alerts in GCP Console
- Review Cloud Run metrics for unexpected traffic

### Getting More Help

If issues persist:

1. **Check detailed logs**:
```bash
# Cloud Build
gcloud builds list
gcloud builds log BUILD_ID

# Cloud Run
gcloud run services logs read gcp-devops-demo --region=asia-east1
```

2. **Consult official documentation**:
   - Cloud Run: https://cloud.google.com/run/docs
   - Cloud Build: https://cloud.google.com/build/docs
   - Terraform: https://registry.terraform.io/providers/hashicorp/google

3. **Community support**:
   - Stack Overflow: Tag questions with `google-cloud-run`, `terraform`, `github-actions`
   - Google Cloud Community: https://www.googlecloudcommunity.com/

---

## 📖 Command Reference

### Git Commands

```bash
# Check status
git status

# View changes
git diff

# Stage files
git add .
git add filename

# Commit
git commit -m "Your message"

# Push to GitHub
git push origin main

# Pull latest
git pull origin main

# View history
git log --oneline

# View remote
git remote -v

# Undo changes to file
git checkout -- filename

# Undo last commit (keep changes)
git reset --soft HEAD~1
```

### gcloud Commands

```bash
# Project management
gcloud projects list
gcloud config set project PROJECT_ID
gcloud config get-value project

# Cloud Run
gcloud run services list
gcloud run services describe SERVICE_NAME --region=REGION
gcloud run services delete SERVICE_NAME --region=REGION
gcloud run services logs read SERVICE_NAME --region=REGION

# Cloud Build
gcloud builds list
gcloud builds describe BUILD_ID
gcloud builds log BUILD_ID

# Artifact Registry
gcloud artifacts repositories list --location=REGION
gcloud artifacts docker images list LOCATION-docker.pkg.dev/PROJECT/REPO

# Service Accounts
gcloud iam service-accounts list
gcloud iam service-accounts describe SA_EMAIL
gcloud iam service-accounts keys list --iam-account=SA_EMAIL

# APIs
gcloud services list --enabled
gcloud services enable SERVICE_NAME
```

### Terraform Commands

```bash
# Initialize
terraform init

# Validate
terraform validate

# Plan (preview changes)
terraform plan

# Apply (create/update resources)
terraform apply

# Destroy (delete resources)
terraform destroy

# Show current state
terraform show

# List resources
terraform state list

# View outputs
terraform output
terraform output OUTPUT_NAME
```

### Docker Commands

```bash
# Build image
docker build -t IMAGE_NAME:TAG .

# List images
docker images

# Run container
docker run -p 8080:8080 IMAGE_NAME:TAG

# List running containers
docker ps

# View logs
docker logs CONTAINER_ID

# Stop container
docker stop CONTAINER_ID

# Remove container
docker rm CONTAINER_ID

# Remove image
docker rmi IMAGE_NAME:TAG
```

---

## 💰 Cost Management

### Expected Costs

For learning/testing purposes:

- **Cloud Run**: $0-5/month (scales to zero when idle)
- **Artifact Registry**: $0.10-1/month (storage for images)
- **Cloud Build**: Free tier includes 120 build-minutes/day
- **Total**: ~$0-10/month for light usage

### Cost Optimization Tips

1. **Scale to Zero**: Ensure Cloud Run min-instances = 0
2. **Delete When Done**: Run `terraform destroy` after learning
3. **Set Billing Alerts**:
   - Go to: https://console.cloud.google.com/billing/
   - Set alert at $10, $25, $50
4. **Clean Up Images**: Old images in Artifact Registry cost storage
5. **Monitor Usage**: Check billing dashboard weekly

### Set Up Billing Alerts

```bash
# Via Console (recommended)
# 1. Go to: https://console.cloud.google.com/billing/
# 2. Click "Budgets & alerts"
# 3. Create budget
# 4. Set threshold alerts
```

---

## 🚀 Next Steps

After successfully completing this project:

### Enhance This Project

1. **Add Database**:
   - Set up Cloud SQL (PostgreSQL)
   - Store data persistently

2. **Add Authentication**:
   - Implement JWT authentication
   - Use Cloud Identity Platform

3. **Add Monitoring**:
   - Set up Cloud Monitoring
   - Create custom dashboards
   - Configure alerting

4. **Add Testing**:
   - Write unit tests (pytest)
   - Add integration tests
   - Include tests in CI/CD

5. **Custom Domain**:
   - Set up Cloud Load Balancer
   - Configure custom domain
   - Add SSL certificate

6. **Blue/Green Deployment**:
   - Implement traffic splitting
   - Gradual rollouts

### Learn More

- **Cloud Run Advanced**: https://cloud.google.com/run/docs
- **Terraform Workspaces**: Manage multiple environments
- **Kubernetes**: Graduate to GKE for more complex apps
- **Workload Identity Federation**: More secure authentication
- **Cloud Armor**: Add DDoS protection and WAF

### Other GCP Services to Explore

- **Cloud Functions**: Serverless functions (event-driven)
- **App Engine**: Fully managed application platform
- **GKE**: Managed Kubernetes for container orchestration
- **Cloud Pub/Sub**: Event-driven messaging
- **Cloud Tasks**: Asynchronous task execution
- **Cloud Scheduler**: Cron-based task scheduling

---

## 📝 Notes

### Security Best Practices

- ✅ Never commit `terraform.tfvars` or `*.json` keys
- ✅ Rotate service account keys regularly (every 90 days)
- ✅ Use least privilege IAM roles
- ✅ Enable audit logging
- ✅ Use secrets management for sensitive data
- ✅ Keep dependencies updated

### Best Practices for Production

- Use Terraform remote state (Cloud Storage backend)
- Implement proper monitoring and alerting
- Set up backup and disaster recovery
- Use Workload Identity instead of service account keys
- Implement proper secret management
- Use Cloud Armor for security
- Set up Cloud CDN for static content
- Implement rate limiting
- Use custom VPC for network isolation

---

## 🎓 Learning Resources

### Official Documentation

- **Google Cloud Run**: https://cloud.google.com/run/docs
- **Google Cloud Build**: https://cloud.google.com/build/docs
- **Artifact Registry**: https://cloud.google.com/artifact-registry/docs
- **Terraform Google Provider**: https://registry.terraform.io/providers/hashicorp/google
- **GitHub Actions**: https://docs.github.com/en/actions
- **Docker**: https://docs.docker.com/

### Tutorials & Courses

- **Google Cloud Skills Boost**: https://www.cloudskillsboost.google/
- **Terraform Learn**: https://learn.hashicorp.com/terraform
- **GitHub Learning Lab**: https://lab.github.com/

### Community

- **r/googlecloud**: https://reddit.com/r/googlecloud
- **Stack Overflow**: Use tags `google-cloud-run`, `terraform`, `github-actions`
- **Google Cloud Community**: https://www.googlecloudcommunity.com/

---

## 📄 License

This project is for educational purposes. Feel free to use and modify for learning.

---

## 🤝 Contributing

Found an issue or want to improve this project? Feel free to:
- Open an issue
- Submit a pull request
- Share your improvements

---

## ✨ Acknowledgments

This project demonstrates industry-standard DevOps practices used by modern development teams. It's designed to be a practical, hands-on learning experience.

---

**🎉 Congratulations on completing this DevOps learning project!**

If you found this helpful, please star the repository and share it with others learning DevOps!

---

**Author**: GCP DevOps Learning Project  
**Last Updated**: January 2025  
**Version**: 1.0.0
