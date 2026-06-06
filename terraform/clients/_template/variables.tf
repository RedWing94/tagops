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
  description = "Custom domain for the sGTM Cloud Run service (e.g. data.clientsite.com)"
  type        = string
}
