variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Run and BigQuery"
  type        = string
  default     = "us-central1"
}

variable "container_config" {
  description = "GTM server container config string (from GTM UI). Treat as secret."
  type        = string
  sensitive   = true
}

variable "custom_domain" {
  description = "Custom domain for the sGTM Cloud Run service (e.g. data.example.com)"
  type        = string
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
  default     = "sgtm-server"
}

variable "dataset_id" {
  description = "BigQuery dataset ID for event storage"
  type        = string
  default     = "tagops_analytics"
}

variable "dataset_location" {
  description = "BigQuery dataset location"
  type        = string
  default     = "US"
}

variable "service_account_id" {
  description = "Service account ID for the Cloud Run sGTM container"
  type        = string
  default     = "sgtm-cloud-run"
}

variable "max_instances" {
  description = "Maximum Cloud Run instances (keep low for free tier)"
  type        = number
  default     = 2
}
