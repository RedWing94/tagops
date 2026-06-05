# TagOps — Server-Side Tracking Reference Build

A fully version-controlled **server-side Google Tag Manager (sGTM)** stack deployed on Google Cloud Run, with event data flowing to BigQuery.

## What's here

| Path | Purpose |
|------|---------|
| `terraform/` | All infrastructure as code (Cloud Run, BigQuery, IAM) |
| `gtm/` | Exported GTM container JSON files (web + server) |
| `docs/` | Architecture diagram, runbook, consent notes |
| `CLAUDE.md` | Project guide for Claude Code |

## Stack

- **Cloud Run** — hosts the sGTM tagging server (`min_instances = 0`, scale-to-zero)
- **BigQuery** — `tagops_analytics` dataset for event storage
- **GTM** — web container (client-side) + server container (server-side)
- **GA4** — existing property, events routed through sGTM
- **Terraform** — provisions and manages all GCP resources

## Quick start

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars   # fill in your values
terraform init
terraform plan
terraform apply
```

## Cost

Designed to run at **$0/month** using GCP free tiers:
- Cloud Run: scale-to-zero, no minimum instances, no load balancer
- BigQuery: free tier (10 GB storage, 1 TB queries/month)

## Owner

Bill Hoerr · [Hoerr Solutions LLC](https://hoerrsolutions.com)
