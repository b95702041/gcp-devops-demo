# Output values to display after Terraform applies changes
# These outputs provide important information needed to interact with the deployed resources

output "cloud_run_url" {
  description = "The URL of the deployed Cloud Run service"
  value       = google_cloud_run_service.app.status[0].url
  
  # This output is sensitive because it's the public URL
  # Set to false since we want users to see this URL
  sensitive = false
}

output "artifact_registry_repository" {
  description = "The full path to the Artifact Registry repository"
  value       = google_artifact_registry_repository.docker_repo.id
}

output "artifact_registry_location" {
  description = "The location of the Artifact Registry repository"
  value       = google_artifact_registry_repository.docker_repo.location
}

output "cloud_run_service_name" {
  description = "The name of the Cloud Run service"
  value       = google_cloud_run_service.app.name
}

output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}
