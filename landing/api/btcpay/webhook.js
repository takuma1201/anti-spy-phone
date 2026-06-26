// ============================================================
//  POST /api/btcpay/webhook
//  Receives BTCPay Server invoice events, verifies the
//  BTCPay-Sig signature over the RAW body, and updates the
//  order/payment status. Idempotent: safe on duplicate/redelivered
//  events (Supabase upsert on the unique btcpay_invoice_id).
// ============================================================

import { verifyWebhookSignature, statusFromEvent } from '../../lib/btcpay.js';

// We need the raw body for HMAC verification — disable body parsing.
export const config = {
  api: { bodyParser: false },
};

function getRawBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', chunk => chunks.push(chunk));
    req.on('end', () => resolve(Buffer.concat(chunks)));
    req.on('error', reject);
  });
}

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).end();

  const rawBody = await getRawBody(req);
  const signature = req.headers['btcpay-sig'];

  // 1. Verify signature over raw bytes.
  if (!verifyWebhookSignature(rawBody, signature)) {
    console.error('[btcpay] webhook signature verification failed');
    return res.status(400).send('Invalid signature');
  }

  // 2. Parse the (now trusted) payload.
  let event;
  try {
    event = JSON.parse(rawBody.toString('utf8'));
  } catch {
    return res.status(400).send('Invalid JSON');
  }

  const status = statusFromEvent(event.type);

  // Always 200 for events we intentionally ignore, so BTCPay
  // does not keep retrying them.
  if (!status) {
    return res.status(200).json({ received: true, ignored: event.type });
  }

  const meta = event.metadata ?? {};
  const order = {
    invoiceId: event.invoiceId,
    orderNum:  meta.orderNum ?? meta.orderId ?? null,
    name:      meta.buyerName ?? null,
    email:     meta.buyerEmail ?? null,
    tel:       meta.tel ?? null,
    address:   meta.address ?? null,
    total:     meta.totalJpy != null ? Number(meta.totalJpy) : null,
    status,
  };

  // 3. Persist + notify (idempotent). Never let one failure block the 200.
  await Promise.allSettled([
    upsertCryptoOrder(order),
    status === 'paid' ? sendOrderNotification(order) : Promise.resolve(),
  ]);

  // Minimal, non-sensitive log (no PII, no secrets).
  console.log(`[btcpay] webhook ${event.type} -> ${status} invoice=${event.invoiceId} order=${order.orderNum}`);

  return res.status(200).json({ received: true });
}

// ── Supabase upsert — idempotent on btcpay_invoice_id ──────────
async function upsertCryptoOrder(order) {
  const SUPABASE_URL =
    process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL;
  const SUPABASE_KEY =
    process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_SERVICE_KEY;
  if (!SUPABASE_URL || !SUPABASE_KEY) return;

  // on_conflict=btcpay_invoice_id + merge-duplicates => idempotent upsert.
  const r = await fetch(
    `${SUPABASE_URL}/rest/v1/crypto_orders?on_conflict=btcpay_invoice_id`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: SUPABASE_KEY,
        Authorization: `Bearer ${SUPABASE_KEY}`,
        Prefer: 'resolution=merge-duplicates,return=minimal',
      },
      body: JSON.stringify({
        btcpay_invoice_id: order.invoiceId,
        order_num: order.orderNum,
        name: order.name,
        email: order.email,
        tel: order.tel,
        address: order.address,
        total_jpy: order.total,
        status: order.status,
      }),
    }
  );

  if (!r.ok) console.error('[btcpay] supabase upsert error:', await r.text());
}

// ── Order notification (only on confirmed payment) ─────────────
async function sendOrderNotification(order) {
  const ENDPOINT = process.env.ORDER_NOTIFY_ENDPOINT;
  if (!ENDPOINT) return;

  await fetch(ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({
      _subject: `【新規注文・Bitcoin決済完了】${order.orderNum} — ${order.name ?? ''}様`,
      orderNum: order.orderNum,
      name: order.name,
      email: order.email,
      tel: order.tel,
      address: order.address,
      method: 'Bitcoin (BTCPay)',
      total: order.total != null ? `¥${order.total.toLocaleString('ja-JP')}` : '',
    }),
  }).catch(e => console.error('[btcpay] notify error:', e));
}
