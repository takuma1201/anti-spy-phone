# Spy Phone — Landing & Checkout

Static landing site (`*.html`) plus Vercel serverless functions (`api/*.js`).
Payments: **Stripe** (cards) and **BTCPay Server** (Bitcoin).

## Stack

- Static HTML, no build step.
- Vercel Node functions in `api/` (ESM).
- Supabase (REST) for order persistence; Formspree-style endpoint for notifications.

---

## Bitcoin payments (BTCPay Server)

Bitcoin payment available as a privacy-respecting payment option, processed
through our own BTCPay Server. All prices are resolved server-side from a
trusted catalog — the client never sets the amount.

### Files

| File | Purpose |
|------|---------|
| `lib/btcpay.js` | Trusted product catalog, Greenfield invoice creation, webhook signature verification. Server-side only. |
| `api/btcpay/create-invoice.js` | `POST /api/btcpay/create-invoice` — resolves the cart, creates a BTCPay invoice, returns the hosted checkout URL. |
| `api/btcpay/webhook.js` | `POST /api/btcpay/webhook` — verifies `BTCPay-Sig`, updates order status (idempotent). |
| `checkout/success.html` · `pending.html` · `cancel.html` | Post-payment pages (`/checkout/success` etc.). |

### Flow

1. Customer adds a product to the cart and opens checkout.
2. Customer fills name / email / address, then clicks **Pay with Bitcoin**.
3. `create-invoice` resolves prices server-side and creates a BTCPay invoice.
4. Customer is redirected to the BTCPay hosted invoice checkout.
5. BTCPay sends a signed webhook to `/api/btcpay/webhook`.
6. The webhook verifies the signature and updates the order status.
7. Customer is returned to `/checkout/success`.

### Environment variables

See `.env.example`. Required for Bitcoin payments:

```
BTCPAY_SERVER_URL=https://btcpay.socialboost.jp
BTCPAY_STORE_ID=<your store id>
BTCPAY_API_KEY=<greenfield api key>
BTCPAY_WEBHOOK_SECRET=<webhook signing secret>
NEXT_PUBLIC_SITE_URL=https://spyphone.socialboost.jp
```

Set these in **Vercel → Project → Settings → Environment Variables**. Never
commit real values; never expose `BTCPAY_API_KEY` in client code.

### BTCPay dashboard setup (required, one-time)

1. **Create / open a Store** in BTCPay at `https://btcpay.socialboost.jp`
   and copy its **Store ID** → `BTCPAY_STORE_ID`.
2. **Create an API key**: Account → Manage Account → API Keys → Generate Key.
   Grant these permissions for the store:
   - `btcpay.store.cancreateinvoice`
   - `btcpay.store.canviewinvoices`
   - `btcpay.store.canviewstoresettings`
   Copy the token → `BTCPAY_API_KEY`.
3. **Create a webhook**: Store → Settings → Webhooks → Create Webhook.
   - **Payload URL**: `https://spyphone.socialboost.jp/api/btcpay/webhook`
   - **Secret**: generate a strong value → `BTCPAY_WEBHOOK_SECRET`
   - **Events**: at minimum `InvoiceSettled`, `InvoiceProcessing`,
     `InvoiceExpired`, `InvoiceInvalid` (or "Send all events").
4. **Run the DB migration**: open `api/schema.sql` in the Supabase SQL editor
   and run it (adds the `crypto_orders` table used by the webhook).
5. Redeploy so the new env vars take effect.

### Trusted catalog

Server-side prices live in `lib/btcpay.js` (`PRODUCTS`). They mirror the live
on-site cart prices so Stripe and BTCPay stay consistent. Update both together
if a price changes.

| id | product | price (JPY) |
|----|---------|-------------|
| `spyphone-pixel8a` | Pixel 8a + GrapheneOS | 140,000 |
| `spyphone-pixel9a` | Pixel 9a + GrapheneOS | 160,000 |
| `spyphone-pixel9` | Pixel 9 + GrapheneOS | 170,000 |
| `spyphone-pixel10a` | Pixel 10a + GrapheneOS | 180,000 |
| `spyphone-pixel10` | Pixel 10 + GrapheneOS | 210,000 |
| `spyphone-pixel10pro` | Pixel 10 Pro + GrapheneOS | 240,000 |
| `spyphone-pixel10proxl` | Pixel 10 Pro XL + GrapheneOS | 255,000 |
| `spyphone-pixel10profold` | Pixel 10 Pro Fold + GrapheneOS | 295,000 |
| `service-conversion` | Pixel書き換えサービス | 80,000 |
| `service-reconfig` | 初期化後 再設定サービス | 50,000 |

Prices mirror the live on-site cart catalogue (the same prices Stripe charges)
so the card and Bitcoin rails stay consistent.

### Security notes

- API key is used server-side only; never sent to the browser.
- Webhook verifies `BTCPay-Sig` = `sha256=HMAC256(secret, rawBody)`.
- Prices are resolved from the trusted catalog; client amounts are ignored.
- Webhook is idempotent (Supabase upsert on the unique `btcpay_invoice_id`),
  so duplicate/redelivered events are safe.
- Logs contain no secrets and minimal PII.
