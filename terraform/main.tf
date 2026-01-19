# Main Terraform configuration for GCP DevOps Demo
# This file defines all the infrastructure needed for the application

# Configure Terraform settings and required providers
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Configure the Google Cloud Provider
# Project and region are provided via variables
provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required Google Cloud APIs
# These APIs must be enabled before creating resources that depend on them
resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudbuild.googleapis.com",      # For Cloud Build CI/CD
    "run.googleapis.com",              # For Cloud Run serverless containers
    "artifactregistry.googleapis.com", # For Docker image storage
  ])

  service = each.value

  # Don't disable the API when removing from Terraform
  # This prevents accidental service disruption
  disable_on_destroy = false
}

# Create Artifact Registry repository for Docker images
# This is where we'll store our built container images
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = "${var.app_name}-repo"
  description   = "Docker repository for ${var.app_name}"
  format        = "DOCKER"

  # Clean up old images automatically to save storage costs
  cleanup_policy_dry_run = false
  
  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"
    
    most_recent_versions {
      keep_count = 10  # Keep the 10 most recent images
    }
  }

  # Ensure API is enabled before creating repository
  depends_on = [google_project_service.required_apis]
}

# Deploy application to Cloud Run
# Cloud Run is a fully managed serverless platform for containerized apps
resource "google_cloud_run_service" "app" {
  name     = var.app_name
  location = var.region

  template {
    spec {
      containers {
        # Initially deploy a placeholder image
        # The actual image will be deployed via Cloud Build pipeline
        image = "gcr.io/cloudrun/hello"

        # Set environment variables for the container
        env {
          name  = "VERSION"
          value = "1.0.0"
        }

        env {
          name  = "ENVIRONMENT"
          value = "production"
        }

        # Resource limits
        # Cloud Run charges based on these limits
        resources {
          limits = {
            cpu    = "1000m"  # 1 CPU
            memory = "512Mi"  # 512 MB RAM
          }
        }

        # Configure health check port
        ports {
          container_port = 8080
        }
      }

      # Auto-scaling configuration
      # Scale to zero when no traffic = no charges
      container_concurrency = 80  # Max concurrent requests per instance
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale" = "0"  # Scale to zero
        "autoscaling.knative.dev/maxScale" = "10" # Max 10 instances
      }
    }
  }

  # Allow unauthenticated traffic (public API)
  # Remove this if you need authentication
  traffic {
    percent         = 100
    latest_revision = true
  }

  # Ensure API is enabled before creating service
  depends_on = [google_project_service.required_apis]

  # Ignore changes to the image tag
  # The CI/CD pipeline will update this automatically
  lifecycle {
    ignore_changes = [
      template[0].spec[0].containers[0].image,
    ]
  }
}

# Allow public access to Cloud Run service
# This makes the API accessible without authentication
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.app.name
  location = google_cloud_run_service.app.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
