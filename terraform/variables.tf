# Variable definitions for Terraform configuration
# These values can be set via terraform.tfvars, environment variables, or command line

variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
  # No default - this must be provided by the user
  # This prevents accidentally deploying to the wrong project
}

variable "region" {
  description = "The GCP region for deploying resources"
  type        = string
  default     = "asia-east1"
  
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "Region must be a valid GCP region format (e.g., asia-east1, us-central1)"
  }
}

variable "app_name" {
  description = "The name of the application (used for resource naming)"
  type        = string
  default     = "gcp-devops-demo"
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.app_name))
    error_message = "App name must start with a letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number"
  }
}
