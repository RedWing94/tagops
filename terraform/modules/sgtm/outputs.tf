output "sgtm_service_account_email" {
  description = "Email of the sGTM Cloud Run service account"
  value       = google_service_account.sgtm.email
}

output "bigquery_dataset_id" {
  description = "BigQuery dataset ID for event data"
  value       = google_bigquery_dataset.analytics.dataset_id
}

output "sgtm_url" {
  description = "Cloud Run URL for the sGTM server"
  value       = google_cloud_run_v2_service.sgtm.uri
}

output "domain_mapping_dns_records" {
  description = "DNS records to add at your hosting provider for the custom domain"
  value       = google_cloud_run_domain_mapping.sgtm.status[0].resource_records
}
