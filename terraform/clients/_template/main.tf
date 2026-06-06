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

  # Optional overrides (uncomment to customize):
  # service_name       = "sgtm-server"
  # dataset_id         = "tagops_analytics"
  # dataset_location   = "US"
  # service_account_id = "sgtm-cloud-run"
  # max_instances      = 2
}
