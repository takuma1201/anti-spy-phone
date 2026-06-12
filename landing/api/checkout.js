import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { orderNum, name, email, tel, address, items, total, ref } = req.body ?? {};

  if (!email || !items?.length) {
    return res.status(400).json({ error: 'email and items are required' });
  }

  const baseUrl = process.env.BASE_URL ?? 'https://spyphone.socialboost.jp';

  try {
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      customer_email: email,
      line_items: items.map(item => ({
        price_data: {
          currency: 'jpy',
          product_data: {
            name: item.name,
            description: item.subtitle ?? undefined,
          },
          unit_amount: item.price,
        },
        quantity: item.qty,
      })),
      mode: 'payment',
      success_url: `${baseUrl}/success?session_id={CHECKOUT_SESSION_ID}&order=${encodeURIComponent(orderNum)}`,
      cancel_url: `${baseUrl}/#pricing`,
      client_reference_id: orderNum,
      metadata: {
        orderNum,
        name,
        tel: tel ?? '',
        address: address ?? '',
        ref: ref ?? '',
      },
      payment_intent_data: {
        metadata: {
          orderNum,
          name,
          email,
          ref: ref ?? '',
        },
      },
      locale: 'ja',
    });

    return res.status(200).json({ url: session.url });
  } catch (err) {
    console.error('Stripe checkout error:', err);
    return res.status(500).json({ error: err.message });
  }
}
