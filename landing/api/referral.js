// Registers a referral-link owner so referrer rewards can be paid out.
// Stores { code → name, email } via Formspree notification + Supabase `referrers`.
export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { code, name, email } = req.body ?? {};
  if (!code || !name || !email) {
    return res.status(400).json({ error: 'code, name and email are required' });
  }

  const cleanCode  = String(code).trim().slice(0, 32);
  const cleanName  = String(name).trim().slice(0, 100);
  const cleanEmail = String(email).trim().toLowerCase().slice(0, 200);

  if (!/^\S+@\S+\.\S+$/.test(cleanEmail)) {
    return res.status(400).json({ error: 'invalid email' });
  }

  const FORMSPREE    = 'https://formspree.io/f/mrejjjwz';
  const SUPABASE_URL = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
  const SUPABASE_KEY = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;

  // ── Formspree メール通知（常に実行）──────────────────────────────
  try {
    await fetch(FORMSPREE, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify({
        _subject: `【紹介者登録】${cleanName}様（${cleanCode}）`,
        name:     cleanName,
        email:    cleanEmail,
        ref_code: cleanCode,
      }),
    });
  } catch (e) {
    console.error('Formspree error:', e);
  }

  // ── Supabase 保存（設定済みの場合のみ・コードでupsert）──────────────
  if (SUPABASE_URL && SUPABASE_KEY) {
    try {
      const r = await fetch(`${SUPABASE_URL}/rest/v1/referrers?on_conflict=code`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Prefer': 'resolution=merge-duplicates,return=minimal',
        },
        body: JSON.stringify({ code: cleanCode, name: cleanName, email: cleanEmail }),
      });
      if (!r.ok) console.error('Supabase referrer error:', await r.text());
    } catch (e) {
      console.error('Supabase referrer error:', e);
    }
  }

  return res.status(200).json({ ok: true });
}
