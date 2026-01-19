# IAM Configuration for GCP DevOps Demo
# This file manages all IAM permissions required for the CI/CD pipeline

# Get project information to construct service account emails
data "google_project" "project" {
  project_id = var.project_id
}

# Local variables for service account emails
locals {
  # Cloud Build default service account (auto-created by GCP)
  cloudbuild_sa = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  
  # GitHub Actions service account (created manually or via gcloud)
  github_sa = "github-actions-sa@${var.project_id}.iam.gserviceaccount.com"
}

# ============================================================================
# GitHub Actions Service Account Permissions
# ============================================================================
# This service account is used by GitHub Actions to authenticate to GCP
# via Workload Identity Federation (no keys needed!)

resource "google_project_iam_member" "github_sa_cloudbuild" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${local.github_sa}"
}

resource "google_project_iam_member" "github_sa_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${local.github_sa}"
}

resource "google_project_iam_member" "github_sa_service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${local.github_sa}"
}

resource "google_project_iam_member" "github_sa_service_usage" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${local.github_sa}"
}

resource "google_project_iam_member" "github_sa_storage" {
  project = var.project_id
  role    = "roles/storage.objectUser"
  member  = "serviceAccount:${local.github_sa}"
}

resource "google_project_iam_member" "github_sa_artifact_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${local.github_sa}"
}

# ============================================================================
# Cloud Build Default Service Account Permissions
# ============================================================================
# This is the default service account used by Cloud Build to execute builds
# Format: [PROJECT_NUMBER]-compute@developer.gserviceaccount.com

resource "google_project_iam_member" "cloudbuild_sa_storage_object_user" {
  project = var.project_id
  role    = "roles/storage.objectUser"
  member  = "serviceAccount:${local.cloudbuild_sa}"
}

resource "google_project_iam_member" "cloudbuild_sa_logs_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${local.cloudbuild_sa}"
}

resource "google_project_iam_member" "cloudbuild_sa_artifact_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${local.cloudbuild_sa}"
}

resource "google_project_iam_member" "cloudbuild_sa_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${local.cloudbuild_sa}"
}

resource "google_project_iam_member" "cloudbuild_sa_service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${local.cloudbuild_sa}"
}

# ============================================================================
# Outputs
# ============================================================================

output "github_service_account" {
  description = "GitHub Actions service account email"
  value       = local.github_sa
}

output "cloudbuild_service_account" {
  description = "Cloud Build default service account email"
  value       = local.cloudbuild_sa
}
