# Consent Mode v2 — TagOps

## Overview

Consent on hoerrsolutions.com is managed by **CookieYes** (CMP) integrated with **Google Consent Mode v2**.

## How it works

1. **CookieYes** displays the consent banner and collects user choices
2. CookieYes sets the Google Consent Mode signals before gtag.js fires:
   - `analytics_storage` — controls GA4 cookies
   - `ad_storage` — controls advertising cookies
   - `ad_user_data` — controls sending user data for ads
   - `ad_personalization` — controls ad personalization
3. The **web GTM container** reads these consent signals via the built-in consent APIs
4. Tags in the web container respect consent state (e.g., GA4 tag honors `analytics_storage`)
5. Events forwarded to the **server container** carry the consent state in the event data
6. Server-side tags can check consent state and gate behavior accordingly

## Consent flow

```
User visits site
       │
       ▼
CookieYes banner shown
       │
       ▼
User grants/denies consent
       │
       ▼
Consent Mode signals updated
(analytics_storage, ad_storage, etc.)
       │
       ▼
gtag.js / web GTM fires tags
respecting consent state
       │
       ▼
Events sent to sGTM with
consent state included
       │
       ▼
Server tags can read consent
state and act accordingly
```

## Default consent state

Before the user interacts with the banner, CookieYes sets a default (denied) state:

```
analytics_storage: denied
ad_storage: denied
ad_user_data: denied
ad_personalization: denied
```

GA4 still fires in "cookieless" mode (no client-side cookies set), sending basic pings. Once the user grants consent, the signals update and full tracking resumes.

## Server-side considerations

- The BigQuery Event Logger streams all events regardless of consent state — it captures the raw server-side payload. The consent fields are included in the `event_data` JSON column for downstream filtering.
- For client-specific deployments, server-side tags can be gated with consent-checking logic to suppress writes when consent is denied.
