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

module "sgtm" {
  source = "../../modules/sgtm"

  project_id       = var.project_id
  region           = var.region
  container_config = var.container_config
  custom_domain    = var.custom_domain
}

# =====================================================
# moved blocks — map old root addresses to module addresses
# so terraform plan shows 0 add, 0 change, 0 destroy
# =====================================================

moved {
  from = google_project_service.cloud_run
  to   = module.sgtm.google_project_service.cloud_run
}

moved {
  from = google_project_service.bigquery
  to   = module.sgtm.google_project_service.bigquery
}

moved {
  from = google_service_account.sgtm
  to   = module.sgtm.google_service_account.sgtm
}

moved {
  from = google_bigquery_dataset.tagops_analytics
  to   = module.sgtm.google_bigquery_dataset.analytics
}

moved {
  from = google_bigquery_table.events
  to   = module.sgtm.google_bigquery_table.events
}

moved {
  from = google_bigquery_dataset_iam_member.sgtm_data_editor
  to   = module.sgtm.google_bigquery_dataset_iam_member.sgtm_data_editor
}

moved {
  from = google_cloud_run_v2_service.sgtm
  to   = module.sgtm.google_cloud_run_v2_service.sgtm
}

moved {
  from = google_cloud_run_v2_service_iam_member.sgtm_public
  to   = module.sgtm.google_cloud_run_v2_service_iam_member.sgtm_public
}

moved {
  from = google_cloud_run_domain_mapping.sgtm
  to   = module.sgtm.google_cloud_run_domain_mapping.sgtm
}
