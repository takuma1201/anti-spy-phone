// ============================================================
//  lib/btcpay.js — BTCPay Server (Greenfield API) helper
//  Server-side ONLY. Never import this from client code.
//
//  Responsibilities:
//   1. Hold the TRUSTED product catalog (prices resolved here,
//      never trusted from the client).
//   2. Create BTCPay invoices via the Greenfield API.
//   3. Verify inbound webhook signatures (BTCPay-Sig HMAC-SHA256).
//
//  Required environment variables (server-side):
//    BTCPAY_SERVER_URL     e.g. https://btcpay.socialboost.jp
//    BTCPAY_STORE_ID       BTCPay store id
//    BTCPAY_API_KEY        Greenfield API key (token)
//    BTCPAY_WEBHOOK_SECRET Webhook signing secret
//    NEXT_PUBLIC_SITE_URL  Public site origin (redirect base)
// ============================================================

import crypto from 'node:crypto';

// ── Trusted product catalog ────────────────────────────────────
// IMPORTANT: these prices are the single server-side source of
// truth for crypto checkout. They mirror the live on-site cart
// catalogue (the same prices Stripe already charges) so the two
// payment rails stay consistent. Client-submitted prices are
// ALWAYS ignored — only the `id` is trusted.
export const PRODUCTS = {
  'spyphone-pixel8a':       { id: 'spyphone-pixel8a',       name: 'SPY Phone — Pixel 8a + GrapheneOS',          price: 140000 },
  'spyphone-pixel9a':       { id: 'spyphone-pixel9a',       name: 'SPY Phone — Pixel 9a + GrapheneOS',          price: 160000 },
  'spyphone-pixel9':        { id: 'spyphone-pixel9',        name: 'SPY Phone — Pixel 9 + GrapheneOS',           price: 170000 },
  'spyphone-pixel10a':      { id: 'spyphone-pixel10a',      name: 'SPY Phone — Pixel 10a + GrapheneOS',         price: 180000 },
  'spyphone-pixel10':       { id: 'spyphone-pixel10',       name: 'SPY Phone — Pixel 10 + GrapheneOS',          price: 210000 },
  'spyphone-pixel10pro':    { id: 'spyphone-pixel10pro',    name: 'SPY Phone — Pixel 10 Pro + GrapheneOS',      price: 240000 },
  'spyphone-pixel10proxl':  { id: 'spyphone-pixel10proxl',  name: 'SPY Phone — Pixel 10 Pro XL + GrapheneOS',   price: 255000 },
  'spyphone-pixel10profold':{ id: 'spyphone-pixel10profold',name: 'SPY Phone — Pixel 10 Pro Fold + GrapheneOS', price: 295000 },
  'service-conversion':     { id: 'service-conversion',     name: 'Pixel書き換えサービス（Pixel 6以上 → GrapheneOS）', price: 80000 },
  'service-reconfig':       { id: 'service-reconfig',       name: '初期化後 再設定サービス',                       price: 50000 },
};

export const CURRENCY = 'JPY';

/**
 * Resolve a client cart against the trusted catalog.
 * Returns { items, total } using ONLY server-side prices, or
 * throws if any product id is unknown / quantity invalid.
 *
 * @param {Array<{id:string, qty?:number, quantity?:number}>} cartItems
 */
export function resolveCart(cartItems) {
  if (!Array.isArray(cartItems) || cartItems.length === 0) {
    throw new Error('Cart is empty');
  }

  const items = [];
  let total = 0;

  for (const raw of cartItems) {
    const id = String(raw?.id ?? '').trim();
    const product = PRODUCTS[id];
    if (!product) {
      throw new Error(`Unknown product id: ${id || '(missing)'}`);
    }

    let qty = Number(raw?.qty ?? raw?.quantity ?? 1);
    if (!Number.isInteger(qty) || qty < 1 || qty > 10) {
      throw new Error(`Invalid quantity for ${id}`);
    }

    const lineTotal = product.price * qty;
    total += lineTotal;
    items.push({ id: product.id, name: product.name, price: product.price, qty });
  }

  if (total <= 0) throw new Error('Resolved total must be positive');
  return { items, total };
}

// ── BTCPay config (read lazily so missing env fails clearly) ────
function btcpayConfig() {
  const serverUrl = (process.env.BTCPAY_SERVER_URL || '').replace(/\/+$/, '');
  const storeId   = process.env.BTCPAY_STORE_ID || '';
  const apiKey    = process.env.BTCPAY_API_KEY || '';
  if (!serverUrl || !storeId || !apiKey) {
    throw new Error('BTCPay is not configured (BTCPAY_SERVER_URL / BTCPAY_STORE_ID / BTCPAY_API_KEY)');
  }
  return { serverUrl, storeId, apiKey };
}

export function siteUrl() {
  return (
    process.env.NEXT_PUBLIC_SITE_URL ||
    process.env.BASE_URL ||
    'https://spyphone.socialboost.jp'
  ).replace(/\/+$/, '');
}

/**
 * Create a BTCPay invoice via the Greenfield API.
 *
 * @param {Object} params
 * @param {number} params.amount     Amount in JPY (integer)
 * @param {Object} params.metadata   Invoice metadata (orderId, buyer info...)
 * @param {string} params.redirectURL Where BTCPay returns the buyer after payment
 * @returns {Promise<{id:string, checkoutLink:string, status:string}>}
 */
export async function createInvoice({ amount, metadata = {}, redirectURL }) {
  const { serverUrl, storeId, apiKey } = btcpayConfig();

  const body = {
    amount: String(amount),
    currency: CURRENCY,
    metadata,
    checkout: {
      redirectURL,
      redirectAutomatically: true,
      defaultLanguage: 'ja-JP',
    },
  };

  const resp = await fetch(`${serverUrl}/api/v1/stores/${storeId}/invoices`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `token ${apiKey}`,
    },
    body: JSON.stringify(body),
  });

  if (!resp.ok) {
    const detail = await resp.text().catch(() => '');
    throw new Error(`BTCPay invoice creation failed (${resp.status}): ${detail.slice(0, 300)}`);
  }

  const invoice = await resp.json();
  return {
    id: invoice.id,
    checkoutLink: invoice.checkoutLink,
    status: invoice.status,
  };
}

/**
 * Verify a BTCPay webhook signature.
 * Header format: `BTCPay-Sig: sha256=<hex hmac>` where the HMAC is
 * computed over the RAW request body bytes with the webhook secret.
 *
 * @param {Buffer|string} rawBody  Raw request body (unparsed)
 * @param {string} signatureHeader Value of the `BTCPay-Sig` header
 * @returns {boolean}
 */
export function verifyWebhookSignature(rawBody, signatureHeader) {
  const secret = process.env.BTCPAY_WEBHOOK_SECRET || '';
  if (!secret || !signatureHeader) return false;

  const expected =
    'sha256=' +
    crypto.createHmac('sha256', secret).update(rawBody).digest('hex');

  const a = Buffer.from(expected);
  const b = Buffer.from(String(signatureHeader));
  // Length check guards timingSafeEqual (which throws on length mismatch)
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

/**
 * Map a BTCPay invoice event type to our internal order status.
 * @param {string} eventType
 * @returns {'paid'|'pending'|'failed'|null}
 */
export function statusFromEvent(eventType) {
  switch (eventType) {
    case 'InvoiceSettled':         // confirmed & settled — fulfil order
    case 'InvoicePaymentSettled':
      return 'paid';
    case 'InvoiceProcessing':      // paid, awaiting confirmations
    case 'InvoiceReceivedPayment':
      return 'pending';
    case 'InvoiceExpired':
    case 'InvoiceInvalid':
      return 'failed';
    default:
      return null;               // InvoiceCreated etc. — ignore
  }
}
