# CookieShift Consent Mode — GTM Community Template

Official Google Tag Manager Community Template for CookieShift Consent Mode v2.

## Install

1. In GTM, open **Templates** → import `template.tpl` (or install from the Gallery when published).
2. Create a tag from **CookieShift Consent Mode**.
3. Enter your **CookieShift Site ID** (UUID from the CookieShift dashboard).
4. Optionally adjust **Consent wait_for_update (ms)** (default **1500**).
5. Fire the tag on **Consent Initialization – All Pages**.

## Important

- Do **not** also install the CookieShift WordPress / Shopify / direct CMP snippet on the same page unless CookieShift documents that combination as compatible.
- This template **owns Google Consent Mode** (`gcm_owner=gtm`). CookieShift does not write Consent Mode via the gtag consent API in that mode.
- Script and API hosts are fixed to `https://cookieshift.com`. There is no field for arbitrary URLs or API keys.

## What it does

1. Sets Consent Mode **defaults** (ad/analytics/functionality denied; `security_storage` granted) with `wait_for_update` (default **1500ms**).
2. Injects `https://cookieshift.com/cmp.js` with Site ID and GTM ownership.
3. Registers `CookieShift.registerConsentListener` and maps categories to Consent Mode via `updateConsentState`:

| CookieShift | Google Consent Mode |
|-------------|---------------------|
| analytics | `analytics_storage` |
| marketing | `ad_storage`, `ad_user_data`, `ad_personalization` |
| preferences | `functionality_storage` |
| necessary | `security_storage` = granted |

## GTM sandbox note

`injectScript` cannot set HTML `data-*` attributes. The template loads:

```text
https://cookieshift.com/cmp.js?site_id=<UUID>&gcm_owner=gtm
```

CookieShift treats those query parameters as equivalent to:

- `data-id="<UUID>"`
- `data-gcm-owner="gtm"`
- `data-api="https://cookieshift.com"` (from script origin)

## Files

| File | Purpose |
|------|---------|
| `template.tpl` | Exportable GTM template (info, fields, code, permissions, tests) |
| `metadata.yaml` | Gallery metadata (commit SHA filled after commit) |
| `LICENSE` | Apache License 2.0 |
| `README.md` | This file |
| `test/template.logic.test.js` | Local Node checks mirroring template logic |

## Gallery

Not submitted yet. After the package is committed, set `metadata.yaml` `versions[].sha` to that commit SHA, then follow Google’s Community Template Gallery process.

## License

Apache License 2.0 — see `LICENSE`.
