# CLAUDE.md — TagOps: Server-Side Tracking Reference Build

> This file is the project guide. Claude Code reads it automatically. Keep it at the repo root.
> Repo: https://github.com/RedWing94/tagops.git · Site: hoerrsolutions.com · Owner: Bill Hoerr (Hoerr Solutions LLC)

---

## What we're building

A production-style, **fully version-controlled server-side tracking stack** on my own site (hoerrsolutions.com). Two purposes:
1. A **live demo / reference build** to show Avenue Z (their team: Nick, Kirk).
2. The **reusable framework ("TagOps")** I'll deploy for client migrations — this repo is my IP.

Everything as code: **Terraform** provisions the infra, a **GTM server container** does the tagging, events flow into **BigQuery**, all tracked in **GitHub**.

---

## ⚠️ Guiding principles — read before doing anything

1. **KEEP IT FREE.** This is a zero-traffic site. These cost guardrails are non-negotiable:
   - Cloud Run **`min_instances = 0`** (scale to zero). NEVER set min instances above 0.
   - Custom domain via **Cloud Run domain mapping**, NEVER a load balancer. A global external load balancer bills ~$18/mo even idle. If domain mapping isn't available in the chosen region, fall back to the default `*.run.app` URL for the demo.
   - Stay inside Cloud Run's free tier (2M requests/mo) and BigQuery's free tier (10 GB storage / 1 TB queries per month).
   - Before every `terraform apply`, confirm: `min_instances = 0` and **no** `google_compute_*` load-balancer resources.

2. **SECURITY.** Never commit secrets, service-account key files, or Terraform state. Use the provided `.gitignore`. Authenticate with Application Default Credentials (`gcloud auth application-default login`) — do **not** create or commit JSON key files.

3. **Separate HUMAN steps from AGENT steps.** Some steps must happen in the GTM web UI, the GCP console (billing), or the domain registrar — Claude Code can't do those. When you hit one, **STOP and tell me exactly what to do** (marked 🙋 below), then continue once I confirm.

4. **Reproducible + documented.** All infra in Terraform. Comment it. Commit at the end of each phase with a clear message.

---

## Stack & exact references (use these values — don't guess)

- **Cloud Run** hosts the sGTM tagging server.
  - Image: `gcr.io/cloud-tagging-10302018/gtm-cloud-image:stable`
  - Required env var: `CONTAINER_CONFIG` (a string I get from the GTM server container setup — treat as a secret, store in `terraform.tfvars`, which is gitignored).
  - Optional preview server = a second Cloud Run service with env `RUN_AS_PREVIEW_SERVER=true`.
  - Flags/settings: port **8080**, `--allow-unauthenticated`, **`--min-instances=0`**, `--max-instances=2`, region `us-central1` (or nearest).
- **Terraform** (open-source CLI — no HCP/Terraform Cloud account needed).
  - Resources: `google_project_service`, `google_service_account`, `google_cloud_run_v2_service`, `google_cloud_run_v2_service_iam_member` (allow unauth), `google_bigquery_dataset`, and **optionally** `google_cloud_run_domain_mapping`. **No** `google_compute_*` LB resources.
  - APIs to enable: `run.googleapis.com`, `bigquery.googleapis.com`.
- **GTM**: existing **web** (client-side) container; we create a **server** container.
- **BigQuery**: dataset `tagops_analytics`.
- **GA4**: existing property.

---

## Prerequisites (verify these with me first)

🙋 **Human (I do these / confirm):**
- [ ] GCP project created, **billing enabled** (free tier, but a billing account is required for Cloud Run). I'll give you the `PROJECT_ID`.
- [ ] `gcloud` CLI installed; ran `gcloud auth login` **and** `gcloud auth application-default login`.
- [ ] Terraform CLI installed.
- [ ] `tagops` repo cloned locally; this `CLAUDE.md` + `.gitignore` copied into the repo root.
- [ ] Access to hoerrsolutions.com DNS at my hosting provider (for a CNAME).
- [ ] Existing GTM web container (have it).

🤖 **Agent (Claude Code does):** repo scaffold, all Terraform, `gcloud`/`terraform` commands, BigQuery dataset + IAM, documentation, and Git commits.

---

## Target repo structure

```
tagops/
├── CLAUDE.md                 # this file
├── README.md                 # human overview
├── .gitignore
├── terraform/
│   ├── main.tf               # provider, APIs, Cloud Run, BigQuery, IAM
│   ├── variables.tf
│   ├── outputs.tf            # run.app URL, dataset, etc.
│   └── terraform.tfvars.example   # template; real tfvars is gitignored
├── gtm/
│   ├── web-container.json    # exported from GTM (committed)
│   └── server-container.json # exported from GTM (committed)
└── docs/
    ├── architecture.md
    └── runbook.md
```

---

## Build plan — phased. Stop at each 🙋 HUMAN step.

### Phase 0 — Scaffold (🤖)
Create the folder structure, `.gitignore`, `README.md`, and a Terraform skeleton (`provider`, `variables.tf`, empty `main.tf`/`outputs.tf`). Initial commit.

### Phase 1 — GCP foundation via Terraform (🤖)
Write + apply Terraform that: enables `run.googleapis.com` and `bigquery.googleapis.com`; creates a service account for Cloud Run; creates the `tagops_analytics` BigQuery dataset; grants the service account `roles/bigquery.dataEditor`. Run `terraform init`, `plan`, `apply`. Confirm no LB resources and no min-instances.

### Phase 2 — 🙋 Create the GTM Server container (HUMAN, GTM UI)
In GTM: **Admin → Create Container → Server**. Choose **"Manually provision tagging server."** Copy the **Container Config** string. Give it to Claude → it goes into `terraform.tfvars` (gitignored), referenced as the `CONTAINER_CONFIG` env var. **Do not commit it.**

### Phase 3 — Deploy sGTM to Cloud Run via Terraform (🤖)
Add a `google_cloud_run_v2_service` running `gcr.io/cloud-tagging-10302018/gtm-cloud-image:stable`, env `CONTAINER_CONFIG`, port 8080, **min_instances = 0**, max 2, allow unauthenticated, region. Apply. Output the `*.run.app` URL. Verify the server is healthy: `curl https://<run-url>/healthy` returns 200.

### Phase 4 — 🙋 Custom subdomain (OPTIONAL, free)
🤖 Attempt `google_cloud_run_domain_mapping` for `data.hoerrsolutions.com`. It will output DNS records.
🙋 I add the CNAME/records at my hosting provider. If domain mapping is unsupported in the region → **skip it and use the run.app URL for the demo.** NEVER add a load balancer to solve this.

### Phase 5 — 🙋 Point the web container at the server (HUMAN, GTM UI)
In the web GTM container, set the GA4 configuration/Google tag's **`server_container_url`** to the sGTM URL. Then **export both containers** (web + server) as JSON and save to `/gtm/`. Commit.

### Phase 6 — GA4 → BigQuery (mixed)
🤖 Confirm the dataset + service-account IAM exist (Terraform).
🙋 In the **server** container, add BigQuery event logging (the standard "write to BigQuery from sGTM" approach) so events land in `tagops_analytics`. Document the tag config in `/docs`.

### Phase 7 — Consent Mode v2 basics (🤖 docs + light config)
Document the consent-gating model and add a short note on CMP integration. Keep it light for the demo, but show the pattern (server tags respect consent state).

### Phase 8 — QA (🤖 guides, I verify)
Verify: `/healthy` = 200; GA4 events appear in **DebugView** flowing via the server; rows landing in the BigQuery dataset; run.app (or subdomain) responding. Capture before/after notes for the demo.

### Phase 9 — Document + push (🤖)
Generate `/docs/architecture.md` (text diagram: browser → sGTM on Cloud Run → GA4 + BigQuery) and `/docs/runbook.md` (how to redeploy, where things live). Push everything to GitHub.

---

## Definition of done (demo-ready)
- sGTM live on Cloud Run (run.app or data.hoerrsolutions.com); `/healthy` returns 200.
- GA4 events flow **through the server** and show in DebugView.
- Events landing in the `tagops_analytics` BigQuery dataset.
- All infra in Terraform, committed to the `tagops` repo, with docs.
- GCP bill ≈ **$0** (pennies at most). Verify: min_instances=0, no load balancer.

---

## Notes for Claude Code
- Ask me for the `PROJECT_ID` and region before writing Terraform.
- After writing Terraform, always run `terraform plan` and show me the plan before `apply`.
- If a step requires the GTM UI, the GCP billing console, or DNS, STOP and give me copy-paste-clear instructions.
- Commit after each phase. Never commit `terraform.tfvars`, `*.tfstate`, or any key file.
