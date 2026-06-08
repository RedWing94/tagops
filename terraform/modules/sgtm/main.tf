# =====================================================
# sGTM Module — reusable server-side GTM infrastructure
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
  account_id   = var.service_account_id
  display_name = "sGTM Cloud Run service account"
}

# --- BigQuery dataset for event storage ---

resource "google_bigquery_dataset" "analytics" {
  dataset_id = var.dataset_id
  location   = var.dataset_location

  description = "Server-side GTM event data for TagOps"

  default_table_expiration_ms = null
}

# --- BigQuery events table (matches the sGTM tag template schema) ---

resource "google_bigquery_table" "events" {
  dataset_id          = google_bigquery_dataset.analytics.dataset_id
  table_id            = "events"
  deletion_protection = false

  schema = jsonencode([
    { name = "event_name",      type = "STRING",  mode = "NULLABLE" },
    { name = "event_timestamp", type = "INTEGER", mode = "NULLABLE" },
    { name = "client_id",       type = "STRING",  mode = "NULLABLE" },
    { name = "page_location",   type = "STRING",  mode = "NULLABLE" },
    { name = "page_referrer",   type = "STRING",  mode = "NULLABLE" },
    { name = "page_title",      type = "STRING",  mode = "NULLABLE" },
    { name = "user_agent",      type = "STRING",  mode = "NULLABLE" },
    { name = "ip_override",     type = "STRING",  mode = "NULLABLE" },
    { name = "event_data",      type = "STRING",  mode = "NULLABLE" }
  ])
}

# --- Grant the sGTM service account write access to BigQuery ---

resource "google_bigquery_dataset_iam_member" "sgtm_data_editor" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.sgtm.email}"
}

# --- Deploy sGTM to Cloud Run ---

resource "google_cloud_run_v2_service" "sgtm" {
  name     = var.service_name
  location = var.region

  depends_on = [google_project_service.cloud_run]

  template {
    # COST GUARD: scale to zero — NEVER set min above 0
    scaling {
      min_instance_count = 0
      max_instance_count = var.max_instances
    }

    service_account = google_service_account.sgtm.email

    containers {
      image = "gcr.io/cloud-tagging-10302018/gtm-cloud-image:stable"

      ports {
        container_port = 8080
      }

      env {
        name  = "CONTAINER_CONFIG"
        value = var.container_config
      }

      # Point the main server at the preview server for GTM debug traffic
      env {
        name  = "PREVIEW_SERVER_URL"
        value = google_cloud_run_v2_service.sgtm_preview.uri
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

# --- Preview server for GTM Server-Side Preview/Debug ---

resource "google_cloud_run_v2_service" "sgtm_preview" {
  name     = "${var.service_name}-preview"
  location = var.region

  depends_on = [google_project_service.cloud_run]

  template {
    # COST GUARD: scale to zero — NEVER set min above 0
    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    service_account = google_service_account.sgtm.email

    containers {
      image = "gcr.io/cloud-tagging-10302018/gtm-cloud-image:stable"

      ports {
        container_port = 8080
      }

      env {
        name  = "CONTAINER_CONFIG"
        value = var.container_config
      }

      env {
        name  = "RUN_AS_PREVIEW_SERVER"
        value = "true"
      }
    }
  }
}

# Allow unauthenticated access (preview server must be reachable by GTM)
resource "google_cloud_run_v2_service_iam_member" "sgtm_preview_public" {
  name     = google_cloud_run_v2_service.sgtm_preview.name
  location = google_cloud_run_v2_service.sgtm_preview.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# --- Custom domain mapping (NO load balancer) ---

resource "google_cloud_run_domain_mapping" "sgtm" {
  name     = var.custom_domain
  location = var.region

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = google_cloud_run_v2_service.sgtm.name
  }
}
