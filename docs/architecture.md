# Architecture — TagOps Server-Side Tracking Stack

## Data flow

```
                         hoerrsolutions.com
                        ┌──────────────────┐
                        │   Browser / App   │
                        │                   │
                        │  gtag.js (web     │
                        │  GTM container)   │
                        └────────┬──────────┘
                                 │
                        HTTPS request with
                        GA4 event payload
                                 │
                                 ▼
              ┌─────────────────────────────────────┐
              │  Cloud Run — sGTM Server Container  │
              │  data.hoerrsolutions.com            │
              │  (sgtm-server-mx3rjhog6a-uc.a.run)  │
              │                                     │
              │  Image: gcr.io/cloud-tagging-       │
              │    10302018/gtm-cloud-image:stable   │
              │  SA: sgtm-cloud-run@tagops-498522   │
              │  min_instances=0, max_instances=2   │
              └──────────┬──────────────┬───────────┘
                         │              │
            ┌────────────┘              └────────────┐
            │                                        │
            ▼                                        ▼
   ┌─────────────────┐                ┌──────────────────────┐
   │   Google        │                │   BigQuery            │
   │   Analytics 4   │                │   tagops-498522.      │
   │                 │                │   tagops_analytics.   │
   │   (GA4 tag in   │                │   events              │
   │   server cont.) │                │                       │
   └─────────────────┘                │   Streaming insert    │
                                      │   via BigQuery Event  │
                                      │   Logger template     │
                                      └──────────────────────┘
```

## Components

### 1. Web GTM container (client-side)

- Runs on hoerrsolutions.com via gtag.js / GTM snippet
- GA4 Google tag configured with `server_container_url` pointing to the sGTM endpoint
- Sends all GA4 events to the server container instead of directly to Google

### 2. Cloud Run — sGTM server container

- **Service:** `sgtm-server` in `us-central1`
- **Image:** `gcr.io/cloud-tagging-10302018/gtm-cloud-image:stable`
- **Custom domain:** `data.hoerrsolutions.com` (Cloud Run domain mapping, CNAME to `ghs.googlehosted.com`)
- **Scaling:** `min_instances=0` (scale to zero), `max_instances=2`
- **Auth:** Public (allUsers → roles/run.invoker)
- **Service account:** `sgtm-cloud-run@tagops-498522.iam.gserviceaccount.com`
- **Health check:** `GET /healthy` → 200 ok

### 3. Server-side tags

| Tag | Destination | Purpose |
|-----|-------------|---------|
| GA4 (built-in) | Google Analytics 4 | Forward events to the GA4 property |
| BigQuery Event Logger (custom) | `tagops_analytics.events` | Stream every event to BigQuery for raw data access |

### 4. BigQuery dataset

- **Project:** `tagops-498522`
- **Dataset:** `tagops_analytics` (location: US)
- **Table:** `events` — 9 columns: `event_name`, `event_timestamp`, `client_id`, `page_location`, `page_referrer`, `page_title`, `user_agent`, `ip_override`, `event_data` (full JSON blob)
- **IAM:** Service account has `roles/bigquery.dataEditor` on the dataset

### 5. Consent

CookieYes CMP handles consent collection on the site. Google Consent Mode v2 signals (`analytics_storage`, `ad_storage`, etc.) are passed through the event data to the server container. See [consent.md](consent.md) for details.

## Infrastructure as code

All GCP resources are managed by Terraform in `/terraform/`. No resources are created manually.

| Terraform resource | GCP resource |
|-------------------|-------------|
| `google_project_service.cloud_run` | Cloud Run API |
| `google_project_service.bigquery` | BigQuery API |
| `google_service_account.sgtm` | Service account |
| `google_cloud_run_v2_service.sgtm` | Cloud Run service |
| `google_cloud_run_v2_service_iam_member.sgtm_public` | Public IAM |
| `google_cloud_run_domain_mapping.sgtm` | Custom domain |
| `google_bigquery_dataset.tagops_analytics` | BigQuery dataset |
| `google_bigquery_table.events` | BigQuery table |
| `google_bigquery_dataset_iam_member.sgtm_data_editor` | IAM binding |

## Cost

Designed for $0/month on GCP free tiers:
- Cloud Run: scale-to-zero, 2M requests/month free
- BigQuery: 10 GB storage + 1 TB queries/month free
- No load balancer (domain mapping only)
