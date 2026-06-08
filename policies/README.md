# Compliance Policy Profiles

Each YAML file in this directory defines a reusable compliance rule-set that controls how the server-side tags and lead pipeline handle consent, PII routing, and data retention.

## How it works

A client selects **one profile** in their `clients/<client>/config.yaml`:

```yaml
policy_profile: ecomm_standard
```

The profile drives:
- **Consent defaults** — which Consent Mode v2 signals are granted or denied by default, per region
- **Tag gating** — which destinations are blocked until the user grants consent
- **PII routing** — whether PII flows to the BigQuery leads vault (raw) and/or to ad platforms (SHA-256 hashed)
- **Retention** — how long raw PII stays in the leads vault before deletion

## Available profiles

| Profile | Use case | PII to ad platforms? | Default consent | Retention |
|---------|----------|---------------------|-----------------|-----------|
| `ecomm_standard` | DTC / e-commerce, US + international | Yes (hashed) | Denied in EU/UK/CH, granted in US | 395 days |
| `eu_strict` | EU-primary or brands wanting strictest GDPR | Yes (hashed, on consent) | Denied everywhere | 365 days |
| `health_strict` | Healthcare, telehealth, wellness | **No** — warehouse only | Denied everywhere | 90 days |
| `finance` | Banks, fintechs, insurance | Yes (hashed, on consent) | Denied everywhere | 365 days |

## Key differences

- **`health_strict`** is the only profile where `ad_platforms_hashed: false`. PHI must never reach ad platforms, even hashed, under HIPAA and the WA My Health My Data Act.
- **`ecomm_standard`** is the only profile with region-specific defaults (EU denied, US granted). All others default to denied everywhere.
- **`eu_strict`** gates GA4 itself (not just ad platforms) — no tag fires at all before consent.
- **`finance`** allows hashed PII to ad platforms (unlike health), because GLBA doesn't carry the same re-identification risk as HIPAA.

## Overriding defaults

A client can override `consent_defaults` in their `config.yaml` to adjust region rules without creating a new profile:

```yaml
policy_profile: ecomm_standard
consent_defaults:
  - regions: [CA]
    analytics_storage: denied
    ad_storage: denied
    ad_user_data: denied
    ad_personalization: denied
```

This adds a California-specific denied default on top of the ecomm_standard profile.
