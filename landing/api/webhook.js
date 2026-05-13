import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

export const config = {
  api: { bodyParser: false },
};

async function getRawBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', chunk => chunks.push(chunk));
    req.on('end', () => resolve(Buffer.concat(chunks)));
    req.on('error', reject);
  });
}

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).end();

  const sig = req.headers['stripe-signature'];
  const rawBody = await getRawBody(req);

  let event;
  try {
    event = stripe.webhooks.constructEvent(
      rawBody,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    await handleOrderCompleted(session);
  }

  return res.status(200).json({ received: true });
}

async function handleOrderCompleted(session) {
  const { orderNum, name, tel, address } = session.metadata ?? {};
  const email = session.customer_email ?? session.customer_details?.email ?? '';
  const total = session.amount_total;

  await Promise.allSettled([
    saveOrderToSupabase({ orderNum, name, email, tel, address, total, sessionId: session.id }),
    sendOrderNotification({ orderNum, name, email, tel, address, total }),
  ]);
}

async function saveOrderToSupabase({ orderNum, name, email, tel, address, total, sessionId }) {
  const SUPABASE_URL = process.env.SUPABASE_URL;
  const SUPABASE_KEY = process.env.SUPABASE_SERVICE_KEY;
  if (!SUPABASE_URL || !SUPABASE_KEY) return;

  const r = await fetch(`${SUPABASE_URL}/rest/v1/orders`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_KEY,
      'Authorization': `Bearer ${SUPABASE_KEY}`,
      'Prefer': 'return=minimal',
    },
    body: JSON.stringify({
      order_num:  orderNum,
      name,
      email,
      tel:        tel ?? null,
      address:    address ?? null,
      total_jpy:  total,
      stripe_session_id: sessionId,
      status:     'paid',
    }),
  });

  if (!r.ok) console.error('Supabase insert error:', await r.text());
}

async function sendOrderNotification({ orderNum, name, email, tel, address, total }) {
  const FORMSPREE = process.env.ORDER_NOTIFY_ENDPOINT;
  if (!FORMSPREE) return;

  await fetch(FORMSPREE, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
    body: JSON.stringify({
      _subject: `【新規注文・決済完了】${orderNum} — ${name}様`,
      orderNum,
      name,
      email,
      tel,
      address,
      total: `¥${total?.toLocaleString('ja-JP')}`,
    }),
  }).catch(e => console.error('Formspree error:', e));
}
