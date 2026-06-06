# Runbook — TagOps Server-Side Tracking Stack

## Quick reference

| What | Where |
|------|-------|
| GCP project | `tagops-498522` |
| Cloud Run service | `sgtm-server` in `us-central1` |
| sGTM URL (run.app) | `https://sgtm-server-mx3rjhog6a-uc.a.run.app` |
| sGTM URL (custom) | `https://data.hoerrsolutions.com` |
| BigQuery dataset | `tagops-498522.tagops_analytics` |
| BigQuery table | `tagops_analytics.events` |
| Service account | `sgtm-cloud-run@tagops-498522.iam.gserviceaccount.com` |
| Terraform dir | `/terraform/` |
| GTM exports | `/gtm/` |
| GitHub repo | `https://github.com/RedWing94/tagops.git` |

## Health check

```bash
curl https://data.hoerrsolutions.com/healthy
# Expected: ok (HTTP 200)

# Fallback if custom domain is down:
curl https://sgtm-server-mx3rjhog6a-uc.a.run.app/healthy
```

## Redeploy the sGTM container

If you change `CONTAINER_CONFIG` (e.g., after recreating the server container in GTM):

1. Update `terraform/terraform.tfvars` with the new config string
2. Run:
   ```bash
   cd terraform/
   terraform plan    # verify only the Cloud Run service changes
   terraform apply
   ```

## Update the sGTM image

Google publishes updates to the `gtm-cloud-image:stable` tag. Cloud Run pulls the latest `:stable` on each cold start (min_instances=0 means every scale-from-zero is a fresh pull). To force an immediate update:

```bash
cd terraform/
terraform apply -replace="google_cloud_run_v2_service.sgtm"
```

## Query events in BigQuery

```sql
-- Last 10 events
SELECT event_name, event_timestamp, page_location, client_id
FROM `tagops-498522.tagops_analytics.events`
ORDER BY event_timestamp DESC
LIMIT 10;

-- Event counts by name (last 24 hours)
SELECT event_name, COUNT(*) as count
FROM `tagops-498522.tagops_analytics.events`
WHERE event_timestamp > UNIX_MILLIS(TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR))
GROUP BY event_name
ORDER BY count DESC;

-- Full event data for a specific client
SELECT *
FROM `tagops-498522.tagops_analytics.events`
WHERE client_id = 'YOUR_CLIENT_ID'
ORDER BY event_timestamp DESC;
```

## GTM container management

### Export containers (for version control)

1. Go to [tagmanager.google.com](https://tagmanager.google.com)
2. **Admin → Export Container** for both web and server containers
3. Save to `gtm/web-container.json` and `gtm/server_container.json`
4. Commit to the repo

### Import the BigQuery Event Logger template

1. Server container → **Templates → Tag Templates → New → ⋮ → Import**
2. Select `gtm/templates/bigquery-event-logger/template.tpl`
3. Save, create a tag using it, set trigger to All Events, publish

## DNS / custom domain

| Record | Type | Name | Value |
|--------|------|------|-------|
| sGTM endpoint | CNAME | `data` | `ghs.googlehosted.com.` |

Managed at the hoerrsolutions.com hosting provider. If you need to change the subdomain, update `var.custom_domain` in Terraform and re-apply.

## Terraform state

- State is stored locally in `terraform/terraform.tfstate` (gitignored)
- **Never commit state files** — they contain sensitive values
- To recover state on a new machine: `terraform import` each resource, or keep a secure backup of the state file

## Cost monitoring

This stack should cost $0/month. If costs appear:

1. Check Cloud Run → verify `min-instances: 0` (no always-on instances)
2. Check there is **no** load balancer in **Network services → Load balancing**
3. Check BigQuery storage → should be well under 10 GB
4. Review the [GCP Billing Console](https://console.cloud.google.com/billing)

## Troubleshooting

| Symptom | Check |
|---------|-------|
| `/healthy` returns error | Cloud Run logs: `gcloud run services logs read sgtm-server --region=us-central1` |
| No events in BigQuery | Preview the server container in GTM → check BigQuery Event Logger tag fires → check for errors in tag console |
| Custom domain not resolving | Verify CNAME `data.hoerrsolutions.com → ghs.googlehosted.com` is active. Check Cloud Run → Domain Mappings for cert status |
| High latency on first request | Expected — cold start from scale-to-zero. Subsequent requests within the instance lifetime are fast |
