terraform {
  required_version = ">= 1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# =====================================================
# Phase 1 — GCP Foundation
# =====================================================

# --- Enable required APIs ---

resource "google_project_service" "cloud_run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "bigquery" {
  service            = "bigquery.googleapis.com"
  disable_on_destroy = false
}

# --- Service account for Cloud Run sGTM container ---

resource "google_service_account" "sgtm" {
  account_id   = "sgtm-cloud-run"
  display_name = "sGTM Cloud Run service account"
}

# --- BigQuery dataset for event storage ---

resource "google_bigquery_dataset" "tagops_analytics" {
  dataset_id = "tagops_analytics"
  location   = "US"

  description = "Server-side GTM event data for TagOps"

  # Free tier: 10 GB storage, 1 TB queries/month
  default_table_expiration_ms = null
}

# --- Grant the sGTM service account write access to BigQuery ---

resource "google_bigquery_dataset_iam_member" "sgtm_data_editor" {
  dataset_id = google_bigquery_dataset.tagops_analytics.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.sgtm.email}"
}
