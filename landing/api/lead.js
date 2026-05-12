export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { name, email, message, page_url } = req.body ?? {};

  if (!name || !email) {
    return res.status(400).json({ error: 'name and email are required' });
  }

  const SUPABASE_URL = process.env.SUPABASE_URL;
  const SUPABASE_KEY = process.env.SUPABASE_SERVICE_KEY;

  if (!SUPABASE_URL || !SUPABASE_KEY) {
    // env not configured yet — accept silently so widget still works in dev
    return res.status(200).json({ ok: true, dev: true });
  }

  const response = await fetch(`${SUPABASE_URL}/rest/v1/chat_leads`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_KEY,
      'Authorization': `Bearer ${SUPABASE_KEY}`,
      'Prefer': 'return=minimal',
    },
    body: JSON.stringify({
      name: name.trim(),
      email: email.trim().toLowerCase(),
      message: message ? message.trim() : null,
      page_url: page_url ?? null,
    }),
  });

  if (!response.ok) {
    const err = await response.text();
    console.error('Supabase error:', err);
    return res.status(500).json({ error: 'Database error' });
  }

  return res.status(200).json({ ok: true });
}
