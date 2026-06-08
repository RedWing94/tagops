output "sgtm_service_account_email" {
  description = "Email of the sGTM Cloud Run service account"
  value       = module.sgtm.sgtm_service_account_email
}

output "bigquery_dataset_id" {
  description = "BigQuery dataset ID for event data"
  value       = module.sgtm.bigquery_dataset_id
}

output "sgtm_url" {
  description = "Cloud Run URL for the sGTM server"
  value       = module.sgtm.sgtm_url
}

output "sgtm_preview_url" {
  description = "Cloud Run URL for the sGTM preview server"
  value       = module.sgtm.sgtm_preview_url
}

output "domain_mapping_dns_records" {
  description = "DNS records to add at your hosting provider for the custom domain"
  value       = module.sgtm.domain_mapping_dns_records
}
