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

# =====================================================
# Phase 3 — Deploy sGTM to Cloud Run
# =====================================================

resource "google_cloud_run_v2_service" "sgtm" {
  name     = "sgtm-server"
  location = var.region

  # Wait for the Cloud Run API to be enabled
  depends_on = [google_project_service.cloud_run]

  template {
    # COST GUARD: scale to zero — never set above 0
    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    service_account = google_service_account.sgtm.email

    containers {
      image = "gcr.io/cloud-tagging-10302018/gtm-cloud-image:stable"

      ports {
        container_port = 8080
      }

      # Container config from GTM — references the sensitive variable, never hardcoded
      env {
        name  = "CONTAINER_CONFIG"
        value = var.container_config
      }
    }
  }
}

# Allow unauthenticated access (public sGTM endpoint)
resource "google_cloud_run_v2_service_iam_member" "sgtm_public" {
  name     = google_cloud_run_v2_service.sgtm.name
  location = google_cloud_run_v2_service.sgtm.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
