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

  const FORMSPREE   = 'https://formspree.io/f/mrejjjwz';
  const SUPABASE_URL = process.env.SUPABASE_URL;
  const SUPABASE_KEY = process.env.SUPABASE_SERVICE_KEY;

  // ── Formspree メール通知（常に実行）───────────────────────────
  try {
    await fetch(FORMSPREE, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify({
        name,
        email,
        message:  message ?? '（メッセージなし）',
        page_url: page_url ?? '',
        _subject: `【AntiSpy 問い合わせ】${name}様より`,
      }),
    });
  } catch (e) {
    console.error('Formspree error:', e);
  }

  // ── Supabase DB保存（設定済みの場合のみ）─────────────────────
  if (SUPABASE_URL && SUPABASE_KEY) {
    try {
      const r = await fetch(`${SUPABASE_URL}/rest/v1/chat_leads`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Prefer': 'return=minimal',
        },
        body: JSON.stringify({
          name:     name.trim(),
          email:    email.trim().toLowerCase(),
          message:  message ? message.trim() : null,
          page_url: page_url ?? null,
        }),
      });
      if (!r.ok) console.error('Supabase error:', await r.text());
    } catch (e) {
      console.error('Supabase error:', e);
    }
  }

  return res.status(200).json({ ok: true });
}
