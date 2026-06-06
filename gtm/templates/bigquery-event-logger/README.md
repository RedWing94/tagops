# BigQuery Event Logger — sGTM Custom Tag Template

Streams every incoming server-side GTM event to BigQuery via `BigQuery.insert()`.

## What it does

1. Calls `getAllEventData()` to capture the full event payload
2. Builds a row with structured fields + a JSON blob of the raw event
3. Inserts the row into `tagops-498522.tagops_analytics.events` via streaming insert
4. The table is auto-created on the first insert (BigQuery streaming insert behaviour)

## BigQuery table schema (auto-created)

| Column | Type | Description |
|--------|------|-------------|
| `event_name` | STRING | GA4 event name |
| `event_timestamp` | INTEGER | Server-side timestamp (epoch ms) |
| `client_id` | STRING | GA4 client ID |
| `page_location` | STRING | Full page URL |
| `page_referrer` | STRING | Referrer URL |
| `page_title` | STRING | Page title |
| `user_agent` | STRING | Browser user-agent |
| `ip_override` | STRING | Client IP |
| `event_data` | STRING | Full event payload as JSON |

## How to import into GTM

1. Open your **server container** in [tagmanager.google.com](https://tagmanager.google.com)
2. Go to **Templates → Tag Templates → New**
3. Click the **three-dot menu (⋮) → Import**
4. Select `template.tpl` from this directory
5. Review the **Permissions** tab — it should show:
   - BigQuery write access to `tagops-498522.tagops_analytics.events`
   - Read all event data
   - Console logging (debug only)
6. Click **Save**

## How to create the tag

1. Go to **Tags → New**
2. Choose **BigQuery Event Logger** as the tag type
3. The fields are pre-filled with defaults — verify:
   - Project ID: `tagops-498522`
   - Dataset ID: `tagops_analytics`
   - Table ID: `events`
4. Set trigger to **All Events** (or create a Custom trigger for all events)
5. **Save → Publish**

## Permissions

- `access_bigquery` — write to `tagops-498522.tagops_analytics.events`
- `read_event_data` — read all event data properties
- `logging` — console logging in debug/preview mode only
