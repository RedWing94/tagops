# Tracking Plan

This directory contains the **TagOps canonical event taxonomy** — the shared contract that every client implementation maps to.

## Files

| File | Purpose |
|------|---------|
| `canonical-events.yml` | Standard event definitions, parameter types, PII routing rules, and the client extension pattern |

## How it works

1. **Canonical events** are the fixed set of event names (page_view, purchase, lead, etc.) that all clients share. They guarantee consistent naming across GTM containers, BigQuery schemas, and dbt models.

2. **Standard params** are defined once with explicit types. Tags and models reference these names exactly — never invent synonyms like `product_id` when `item_id` exists.

3. **PII fields** have strict routing rules: raw to the BigQuery leads vault, SHA-256 hashed to ad platforms, and never to GA4.

4. **Client extensions** live in each client's `config.yaml`. Clients pick which canonical events they use and add `custom_events` for anything bespoke. Custom events must not collide with canonical names and can reuse standard params by reference.

## What this drives

- **GTM tag generation** — canonical event names map 1:1 to server-side tag triggers
- **BigQuery table schemas** — the `standard_params` types define column types in the events table
- **dbt models** — downstream transformations reference canonical names, so a model written for one client works for any client using the same events
- **QA validation** — events not in the canonical + custom list are flagged as unexpected
