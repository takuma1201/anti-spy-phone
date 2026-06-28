// ============================================================
//  POST /api/btcpay/create-invoice
//  Creates a BTCPay (Greenfield) invoice for the customer's cart
//  and returns the hosted checkout URL. All prices are resolved
//  server-side from the trusted catalog — the client price/total
//  are never trusted.
// ============================================================

import { resolveCart, createInvoice, siteUrl } from '../../lib/btcpay.js';

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { orderNum, name, email, tel, address, items, ref } = req.body ?? {};

  if (!email || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'email and items are required' });
  }

  // Resolve cart against the trusted server-side catalog.
  let resolved;
  try {
    resolved = resolveCart(items);
  } catch (err) {
    return res.status(400).json({ error: err.message });
  }

  const orderId = (orderNum && String(orderNum).trim()) ||
    'SPY-' + Math.random().toString(36).toUpperCase().slice(2, 8);

  const itemDesc = resolved.items
    .map(i => `${i.name}${i.qty > 1 ? ` ×${i.qty}` : ''}`)
    .join(', ');

  try {
    const invoice = await createInvoice({
      amount: resolved.total,
      redirectURL: `${siteUrl()}/checkout/success?order=${encodeURIComponent(orderId)}`,
      metadata: {
        // Shown in BTCPay dashboard:
        orderId,
        itemDesc,
        // Used by our webhook to fulfil the order:
        orderNum: orderId,
        buyerName: name ?? '',
        buyerEmail: email,
        tel: tel ?? '',
        address: address ?? '',
        productIds: resolved.items.map(i => i.id).join(','),
        totalJpy: resolved.total,
        ref: ref ?? '',          // referral code (recorded; reward flow is Stripe-only)
        source: 'spyphone-web',
      },
    });

    if (!invoice.checkoutLink) {
      throw new Error('BTCPay did not return a checkout link');
    }

    // Minimal, non-sensitive log.
    console.log(`[btcpay] invoice created: ${invoice.id} order=${orderId} total=¥${resolved.total}`);

    return res.status(200).json({
      url: invoice.checkoutLink,
      invoiceId: invoice.id,
      orderNum: orderId,
    });
  } catch (err) {
    console.error('[btcpay] create-invoice error:', err.message);
    return res.status(502).json({ error: 'Failed to create Bitcoin invoice. Please try again.' });
  }
}
