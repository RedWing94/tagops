# CLAUDE.md — TagOps: Server-Side Tracking Platform
> **This is the single source of truth.** Claude Code auto-reads this file at the repo root. Everything you need — architecture, current state, file map, consent design, and prioritized next steps — is here.
> Repo: https://github.com/RedWing94/tagops.git · GCP project: `tagops-498522` · Site: hoerrsolutions.com · Owner: Bill Hoerr (Hoerr Solutions LLC)

---

## 1. What we're building & why

A production-grade, **fully version-controlled server-side tracking platform** ("TagOps"). Two purposes:
1. A **live reference build** on hoerrsolutions.com to demo to Avenue Z (Nick, Kirk).
2. The **reusable framework** I deploy for client migrations — this repo is my IP.

**The one idea that makes it scale:** a client is **not a custom build — it's a config file.** Avenue Z onboards a client by filling out one `config.yaml`; generators stand up the entire compliant stack (server container, ad-platform connections, first-party data into BigQuery, PII handled per the client's vertical, standardized dbt models) with no bespoke work. 40+ clients, one system, maintained by me + Kirk instead of a 40-person team.

Everything as code: **Terraform** provisions infra · a **GTM server container** does the tagging · events flow into **BigQuery** · **dbt** shapes the data · all tracked in **GitHub**.

---

## 2. Current state — built vs. planned

**✅ BUILT (Crawl + most of Walk):**
- Terraform module (`modules/sgtm`) + Hoerr live on Cloud Run (main + preview servers)
- GitHub monorepo
- GA4 flowing **through the server**; events landing in BigQuery
- Custom **BigQuery event logger** template with a **CMP-agnostic consent gate** (reads `x-ga-gcs`) — live↔repo synced
- **Canonical tracking plan** (`tracking-plan/canonical-events.yml`)
- Shared **dbt** package: staging + 3 marts (sessions, conversions, page_views) + tests — **14/14 passing**
- All four **policy profiles authored** (`ecomm_standard`, `eu_strict`, `health_strict`, `finance`) — *definitions exist; server-side enforcement wiring is still 🔜*

**🔜 PLANNED (rest of Walk → Run) — see §8 for order:**
- Elementor form listener (quick win — Elementor leads currently invisible)
- Server-side **lead/PII capture** (webhook → leads vault)
- Destination templates: **Meta CAPI**, Google Ads Enhanced Conversions, TikTok, Snapchat
- **GTM API onboarding script** (auto-create containers from config) — the keystone
- **CI/CD** (GitHub Actions), Kestra-scheduled dbt, the AI layer

---

## 3. Guiding principles — read before doing anything

1. **KEEP IT FREE.** Zero-traffic site. Non-negotiable:
   - Cloud Run **`min_instances = 0`** (scale to zero). NEVER above 0.
   - Custom domain via **Cloud Run domain mapping**, NEVER a load balancer (an LB bills ~$18/mo even idle). If domain mapping isn't available in-region, fall back to the `*.run.app` URL.
   - Stay inside Cloud Run free tier (2M req/mo) and BigQuery free tier (10 GB storage / 1 TB queries/mo).
   - Before every `terraform apply`, confirm `min_instances = 0` and **no** `google_compute_*` LB resources.
2. **SECURITY.** Never commit secrets, service-account keys, or Terraform state. Use `.gitignore`. Auth via Application Default Credentials (`gcloud auth application-default login`) — never create/commit JSON key files.
3. **Separate HUMAN steps from AGENT steps.** Some steps need the GTM UI, GCP billing console, or DNS — Claude Code can't do those. When you hit one, **STOP and give exact copy-paste instructions** (marked 🙋), then continue once confirmed.
4. **Reproducible + documented.** All infra in Terraform, commented. Commit at the end of each phase with a clear message. Run `terraform plan` and show it before `apply`.

---

## 4. Architecture — two planes

- **Control plane (the factory, build-time):** how each client's stack gets created/updated. GitHub + Terraform + GTM API script. Runs when you onboard or change a client.
- **Data plane (the running machine, run-time):** how a user's data actually flows. Cloud Run + GTM containers + BigQuery. Runs on every site interaction.

**Data flow (run-time):**
```
User browser ──first-party──> sGTM on Cloud Run (the routing hub)
   ├─ no PII, consent-gated ──────────────> GA4 (reporting)
   ├─ SHA-256 hashed PII ─────────────────> Meta CAPI / TikTok / Snapchat
   ├─ sanctioned hashed user data ────────> Google Ads Enhanced Conversions
   └─ full raw record ────────────────────> BigQuery (raw events + leads vault)
                                                  └─> dbt (staging → marts → tests) ─> BI / AI
Form platform ──webhook (server-to-server, full lead)──> sGTM
```

**PII routing — the rule to bank:** PII never touches GA4 in any form. It lives in your BigQuery warehouse (raw) and reaches ad platforms only through their sanctioned **hashed** conversion APIs (Meta CAPI, Google Enhanced Conversions, TikTok/Snap Events APIs). The server is where you enforce this — client-side cannot, which is the whole reason server-side exists.

| Destination | Receives |
|---|---|
| GA4 | Events + non-PII params. **No PII, not even hashed.** |
| Google Ads | Conversions via Enhanced Conversions (the only sanctioned PII→Google path). |
| Meta / TikTok / Snap | Conversions with SHA-256-hashed email/phone/name; technical fields (IP, UA, click IDs) raw. |
| Your BigQuery | The full record, raw PII — your warehouse, governed by the client's policy profile. |

**Dedup:** one `event_id` per conversion, sent on both the browser pixel and the server API call; platforms dedupe matching IDs within ~48h.

---

## 5. Repo structure & file-by-file map

*(Reconciled against the actual repo tree, June 2026.)*
```
tagops/
├── CLAUDE.md                       # THIS FILE — single source of truth ✅
├── README.md  ·  .gitignore                                                                    ✅
├── terraform/
│   ├── modules/sgtm/               # reusable: Cloud Run (main+preview), BigQuery, IAM, domain ✅
│   │   └── main.tf · variables.tf · outputs.tf
│   ├── clients/hoerr/              # Hoerr LIVE deploy (calls module); tfvars gitignored        ✅
│   │   └── main.tf · variables.tf · outputs.tf · terraform.tfvars.example
│   └── clients/_template/          # onboarding kit                                             ✅
│       └── main.tf · variables.tf · outputs.tf · terraform.tfvars.example · config.yaml · README.md
├── gtm/
│   ├── web-container.json · server_container.json     # exported, versioned (note: underscore) ✅
│   └── templates/bigquery-event-logger/               # custom logger + consent gate           ✅
│       └── template.tpl · README.md
│   # 🔜 to add: templates/ for meta-capi, google-ads, tiktok, snapchat, consent-bridge
├── tracking-plan/                       # the contract: standard events/params + PII rule       ✅
│   └── canonical-events.yml · README.md
├── policies/                            # all 4 authored ✅ (enforcement wiring 🔜)
│   └── ecomm_standard.yml · eu_strict.yml · health_strict.yml · finance.yml · README.md
├── dbt/
│   ├── dbt_project.yml · packages.yml · profiles.example.yml · models/sources.yml              ✅
│   ├── models/staging/stg_events.sql (+.yml)   # parse raw JSON → typed columns                 ✅
│   └── models/marts/fct_sessions|fct_conversions|fct_page_views .sql (+.yml)  # 14/14 tests     ✅
├── docs/                                # architecture.md · runbook.md · consent.md             ✅
├── scripts/gtm_onboard/                 # GTM API onboarding script (auto-create containers)    🔜
└── .github/workflows/                   # CI/CD: merge config → terraform + gtm + dbt           🔜
```

**Key files explained:**
- **`CLAUDE.md`** — this guide. Cost guardrails, security rules, architecture, plan.
- **`terraform/modules/sgtm/`** — the reusable blueprint for ONE client's cloud: Cloud Run main + preview tagging servers, BigQuery dataset (`tagops_analytics`) + `events` table, service account + IAM (Cloud Run → BigQuery write), optional domain mapping. One module, every client; `variables.tf` is the knobs, `outputs.tf` returns the run.app URL etc.
- **`terraform/clients/<client>/`** — calls the module with that client's values. `_template/config.yaml` is the **single source of truth** per client (domain, `policy_profile`, `cmp`, `consent_defaults`, destinations, events).
- **`gtm/templates/bigquery-event-logger/template.tpl`** — sandboxed-JS GTM tag that writes every server event to BigQuery. Contains the consent gate. 5 sections: `___INFO___`, `___TEMPLATE_PARAMETERS___`, `___SANDBOXED_JS_FOR_SERVER___` (code), `___SERVER_PERMISSIONS___` (BigQuery write + read-event-data + logging), `___TESTS___`.
- **`tracking-plan/canonical-events.yml`** — the keystone. Standard event vocabulary (`page_view`, `lead` w/ `type` param, `purchase`…) every client maps to. This is what lets one dbt package + one AI layer serve all clients.
- **`policies/<profile>`** — reusable compliance rulebooks the server reads. Define "what health clients may do" once, apply to every health client.
- **`dbt/`** — staging (views, parse JSON → canonical shape) + marts (tables for BI/AI) + tests (tracking QA as code).

---

## 6. Consent across all CMPs (CookieYes, OneTrust, Osano, Cookiebot…)

**The server is CMP-agnostic — by design.** Every major CMP integrates with **Google Consent Mode v2** and emits the same standardized signal on a visitor's choice:
```js
gtag('consent','update',{analytics_storage:'granted', ad_storage:'denied', ad_user_data:'denied', ad_personalization:'denied'});
```
That state reaches the server as **`x-ga-gcs`** = `G1<ad_storage><analytics_storage>`. The BigQuery logger reads index 3; it never asks which CMP set it. **The gate is already CMP-agnostic.**

Per-CMP differences are **front-end + config only**:
1. **`config.yaml` declares the CMP** (`cmp: cookieyes|onetrust|osano|…` + `consent_defaults`) → tells the onboarding script which install pattern to wire into the **web** container.
2. **The web container** carries the CMP's Consent Mode integration (native for CookieYes/OneTrust/Osano/Cookiebot). For a CMP without native Consent Mode v2, write one small **consent bridge** (listens for the CMP's event → emits the `gtag consent update`) and reuse it across all clients on that CMP.
3. **The server + `policy_profile`** enforce generically off `x-ga-gcs` (`eu_strict` = nothing fires before opt-in; `health_strict` = warehouse only, no marketing tags).

**Bottom line:** standardize on Consent Mode v2 as the contract; declare the CMP in config; enforce server-side generically. One server codebase for all CMPs.

---

## 7. Stack & exact references (use these — don't guess)

- **Cloud Run** hosts the sGTM server.
  - Image: `gcr.io/cloud-tagging-10302018/gtm-cloud-image:stable`
  - Env: `CONTAINER_CONFIG` (from GTM server container setup — secret, in gitignored `terraform.tfvars`). Preview server = second service with `RUN_AS_PREVIEW_SERVER=true`; main server gets `PREVIEW_SERVER_URL`.
  - Port **8080**, `--allow-unauthenticated`, **`--min-instances=0`**, `--max-instances=2`, region `us-central1`.
- **Terraform** (open-source CLI; no HCP account). Resources: `google_project_service`, `google_service_account`, `google_cloud_run_v2_service`, `google_cloud_run_v2_service_iam_member`, `google_bigquery_dataset`, optional `google_cloud_run_domain_mapping`. **No `google_compute_*`.** APIs: `run.googleapis.com`, `bigquery.googleapis.com` (add `tagmanager.googleapis.com` when building the onboarding script).
- **BigQuery:** project `tagops-498522`, dataset `tagops_analytics`, table `events`. dbt writes to `dbt_marts`.
- **GTM:** existing web container; server container created per client.

**Auth gotcha for the GTM API script:** the service account's email must be added as a **User in the GTM account** (User Management) with **Edit + Publish** before the API works — the API call alone isn't enough.

---

## 8. Roadmap & next steps — crawl / walk / run

**✅ Crawl (done):** one client live, Terraform module, monorepo, GA4 + BigQuery, custom logger w/ consent gate.

**🔜 Walk (next, in priority order):**
1. **Elementor form listener** — *quick win.* Site is CF7 + Elementor; only CF7 fires `cf7_submission`, so Elementor leads are invisible. Add a `submit_success` listener → GA4 event (non-PII params only). Mind the ~500ms redirect race.
2. **Server-side lead/PII capture** — webhook → `leads` vault in BigQuery (raw PII), with SHA-256 hashing for ad platforms. *This unlocks the Meta CAPI play — the part Avenue Z actually pays for.*
3. **Meta CAPI template** — first real ad-platform destination tag (`gtm/templates/meta-capi/`). Then TikTok/Snapchat/Google Ads.

**🔜 Run (the platform):**
4. **GTM API onboarding script** (`scripts/gtm_onboard/`) — reads `config.yaml`, auto-creates web + server containers via **Tag Manager API v2**, imports `.tpl` templates, wires destination tags + triggers, publishes, emits `CONTAINER_CONFIG` → tfvars. **Research/confirm exact API v2 endpoints + field names before writing code — don't guess.** Make idempotent (use fingerprints), add `--dry-run`, handle rate limits. Build against Hoerr first (reproduce the existing container from config to prove parity), then it generalizes. *This is the keystone that makes onboarding a config change.*
5. **CI/CD** (GitHub Actions): merge config → Terraform apply + GTM onboarding + dbt deploy. Orchestration order: GTM Phase A (server container → `CONTAINER_CONFIG`) → Terraform apply (Cloud Run) → GTM Phase B (web container w/ live `server_url`).
6. **Kestra** scheduled dbt + monitoring.
7. **AI layer** — container intelligence ("what fires for client X?") + data intelligence (NL→SQL over canonical marts).

---

## 9. How to work with me (Claude Code)

- Ask for `PROJECT_ID`/region before writing Terraform if unset.
- Always `terraform plan` and show it before `apply`. Confirm `min_instances=0` and no LB every time.
- When a step needs the GTM UI, GCP billing, or DNS, **STOP** and give exact copy-paste instructions.
- Commit after each phase. Never commit `terraform.tfvars`, `*.tfstate`, or key files.
- For the GTM API and any platform API: **research and confirm the real endpoints/field shapes before coding.**