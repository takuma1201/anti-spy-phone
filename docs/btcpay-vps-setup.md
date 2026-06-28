# BTCPay Server — VPS 本番構築手順書

SPY Phone EC サイト（`spyphone.socialboost.jp`）に **Bitcoin（BTCPay Server）決済**を本番導入するための手順書。

- 決済方式: **Bitcoin オンチェーン優先**（Lightning は後回し）
- 受取ウォレット: **Sparrow Wallet**（**ウォッチオンリー** = xpub/zpub/descriptor 連携）
- **BTCPay にシード・秘密鍵は入れない**（公開鍵のみで受取監視）
- BTCPay 本体は **Linux VPS** で運用。Mac は開発・SSH・Git 用、iPhone は管理確認用。

---

## 0. なぜ Mac ではなく VPS で動かすのか

| 理由 | 内容 |
|---|---|
| **公開到達性** | BTCPay は `btcpay.socialboost.jp` で外部公開し、Vercel の Webhook（`/api/btcpay/webhook`）から到達される必要がある。Mac は NAT 内・非公開 IP のため不可。 |
| **常時起動** | 決済受付・ブロックチェーン監視のため 24/365 稼働が必要。ノート PC は不適。 |
| **スクリプトが Linux 専用** | 公式 `btcpay-setup.sh` は Ubuntu/Debian 前提（systemd・apt）。macOS では `command not found` となり完走しない。 |
| **TLS 証明書** | Let's Encrypt がドメイン検証で公開 IP を要求する。 |

→ **本番 BTCPay は必ず Linux VPS 上**。Mac からは SSH で操作するだけ。

---

## 1. 推奨 VPS

### 推奨: ConoHa VPS 4GB（国内）
- **Ubuntu 22.04 LTS**
- メモリ **4GB** / **100GB SSD** / 3〜4 vCPU
- 概算 **約 ¥3,600/月**
- 国内データセンター・JPY 決済・日本語管理画面

### 無料案: Oracle Cloud Always Free（ARM）
- 無期限無料の **Ampere A1**（最大 4 OCPU / 24GB / ブロック 200GB）で BTCPay 稼働可。
- 容量品薄・SLA なし等の注意あり。専用手順は [`btcpay-oracle-free-setup.md`](./btcpay-oracle-free-setup.md)。

### 低コスト案: Hetzner Cloud CPX21
- **Ubuntu 22.04 LTS**
- 3 vCPU / 4GB / 80GB SSD
- 概算 **約 €8（約 ¥1,300）/月**
- 最安・高性能（日本リージョンはなし＝レイテンシは決済用途では実用上問題なし）

### スペック指針
| 項目 | 最低 | 推奨 |
|---|---|---|
| RAM | 2GB | **4GB** |
| ディスク | 60GB SSD | **80〜100GB SSD** |
| CPU | 1 vCPU | 2 vCPU |
| OS | — | **Ubuntu 22.04 LTS** |

> Bitcoin フルノードは 600GB 超だが、本手順は **プルーンド設定（`opt-save-storage-s` ≒ 約 30GB）** で運用するため 80〜100GB で十分。初回ブロック同期は数時間〜1 日程度。

---

## 2. DNS 設定

Xserver Domain（`socialboost.jp` のネームサーバー: `ns1〜3.xdomain.ne.jp`）の管理画面で **A レコード**を追加:

| ホスト名 | 種別 | 値 |
|---|---|---|
| `btcpay` | A | VPS のグローバル IPv4 |

確認（反映後、Mac のターミナルで）:
```bash
dig +short btcpay.socialboost.jp     # → VPS の IP が返ればOK
```

> **必ず DNS 反映を待ってから** BTCPay セットアップを実行すること（Let's Encrypt 証明書取得がドメイン検証に依存するため）。

---

## 3. SSH 接続

VPS 作成時に登録した公開鍵 or パスワードで接続:
```bash
ssh root@<VPSのIP>
# 鍵を指定する場合: ssh -i ~/.ssh/your_key root@<VPSのIP>
```

最低限の初期セキュリティ（推奨）:
```bash
# UFW で必要ポートのみ開放（22/SSH, 80/443/HTTPS）
ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp && ufw --force enable
```

---

## 4. BTCPay Server インストール（Docker・BTC オンチェーンのみ）

VPS 上で実行。**Lightning は最初は入れない**（`BTCPAYGEN_LIGHTNING` を設定しない）:

```bash
sudo su -
mkdir -p /opt/btcpay && cd /opt/btcpay
git clone https://github.com/btcpayserver/btcpayserver-docker
cd btcpayserver-docker

export BTCPAY_HOST="btcpay.socialboost.jp"
export NBITCOIN_NETWORK="mainnet"
export BTCPAYGEN_CRYPTO1="btc"
export BTCPAYGEN_ADDITIONAL_FRAGMENTS="opt-save-storage-s"   # プルーンド（≒30GB）
export BTCPAY_ENABLE_SSH=true
# ↑ Lightning は意図的に未設定（後日 BTCPAYGEN_LIGHTNING="clightning" で追加可能）

. ./btcpay-setup.sh -i
```

完了後:
- `https://btcpay.socialboost.jp` にアクセス → 管理者アカウント登録
- Bitcoin ノードの初回同期完了まで待機（同期中も UI 設定は進められる）

同期状況の確認:
```bash
cd /opt/btcpay/btcpayserver-docker
./btcpay-down.sh   # 停止（必要時のみ）
docker logs -f btcpayserver_bitcoind_1   # 同期ログ
```

### Lightning を後で追加する場合（任意・本番安定後）
```bash
cd /opt/btcpay/btcpayserver-docker
export BTCPAYGEN_LIGHTNING="clightning"
. ./btcpay-setup.sh -i
```

---

## 5. Sparrow Wallet 連携（ウォッチオンリー / シードを入れない）

**方針**: 秘密鍵・シードは **Sparrow 側（あるいはハードウェアウォレット）にのみ**保持し、BTCPay には **公開鍵（xpub/zpub）または output descriptor** だけを登録する。これにより BTCPay が侵害されても資金は移動できない（受取監視のみ）。

### 手順
1. **Sparrow** でウォレットを用意（既存 or 新規。新規時はシードを Sparrow / ハードウェアで安全に保管）。
2. Sparrow → 対象ウォレット → **Settings** → 右上 **Export...**（または **Settings → Export → Output Descriptor / xpub/zpub**）。
   - ネイティブ SegWit（bc1）なら **zpub**、または **descriptor**（`wpkh([fingerprint/84h/0h/0h]zpub.../0/*)`）を取得。
3. **BTCPay** → 対象 Store → **Settings → Wallets → Bitcoin → Setup → Connect an existing wallet → Enter extended public key**。
   - コピーした **zpub**（または descriptor）を貼り付け。
   - **Account key path / fingerprint** を Sparrow の表示に合わせる（descriptor を使うと自動で整合しやすい）。
4. 保存後、BTCPay が生成する受取アドレスが **Sparrow と一致**することを確認（最初の数アドレスを照合）。

> BTCPay には「Hot wallet（シードを BTCPay に持たせる）」オプションもあるが、**本構成では使用しない**。必ず xpub/zpub/descriptor の **Watch-only** で接続する。

---

## 6. Store・API Key・Webhook 設定（BTCPay 管理画面）

### 6-1. Store 作成 → Store ID 取得
- BTCPay → **Create Store**（例: "SPY Phone"）
- **Settings → General** の URL またはダッシュボードに表示される **Store ID** を控える → `BTCPAY_STORE_ID`

### 6-2. API Key 作成
- 右上アカウント → **Manage Account → API Keys → Generate Key**
- 付与する権限（最小権限）:
  - `btcpay.store.cancreateinvoice`
  - `btcpay.store.canviewinvoices`
  - `btcpay.store.canviewstoresettings`
- 生成されたトークンを控える → `BTCPAY_API_KEY`（**サーバー専用。クライアントに出さない**）

### 6-3. Webhook 作成
- Store → **Settings → Webhooks → Create Webhook**
  - **Payload URL**: `https://spyphone.socialboost.jp/api/btcpay/webhook`
  - **Secret**: 強力なランダム値を生成して入力 → `BTCPAY_WEBHOOK_SECRET`
  - **Events**: 最低限 `InvoiceSettled` / `InvoiceProcessing` / `InvoiceExpired` / `InvoiceInvalid`（または "Send all events"）
  - **Automatic redelivery** は有効のままで可（当サイトの Webhook は**冪等**なので重複・再送は安全）

---

## 7. Vercel 環境変数

Vercel → Project `spy-phone` → **Settings → Environment Variables**（Production）に設定:

```
BTCPAY_SERVER_URL=https://btcpay.socialboost.jp
BTCPAY_STORE_ID=        ← 6-1 で取得
BTCPAY_API_KEY=         ← 6-2 で取得（サーバー専用）
BTCPAY_WEBHOOK_SECRET=  ← 6-3 で生成
NEXT_PUBLIC_SITE_URL=https://spyphone.socialboost.jp
```

設定後、**再デプロイ**して反映（環境変数はビルド/関数に再読込が必要）。

---

## 8. Supabase スキーマ実行

Supabase Dashboard → **SQL Editor** で `landing/api/schema.sql` の **`crypto_orders`** テーブル定義を実行:

```sql
create table if not exists crypto_orders (
  id                uuid        default gen_random_uuid() primary key,
  btcpay_invoice_id text        not null unique,   -- 冪等キー（重複Webhook安全）
  order_num         text,
  name              text,
  email             text,
  tel               text,
  address           text,
  total_jpy         integer,
  status            text        not null default 'pending',  -- pending | paid | failed
  created_at        timestamptz default now(),
  updated_at        timestamptz default now()
);
create index if not exists crypto_orders_order_num_idx on crypto_orders (order_num);
create index if not exists crypto_orders_email_idx     on crypto_orders (email);
alter table crypto_orders enable row level security;
```

---

## 9. 本番テスト手順

1. **DNS/TLS**: `https://btcpay.socialboost.jp` が有効な証明書で開ける。
2. **同期**: Bitcoin ノードが同期完了（BTCPay の Store ダッシュボードが "synced" 表示）。
3. **インボイス生成**: サイトでカート → チェックアウト → **「Pay with Bitcoin」** → BTCPay のインボイス画面に遷移する。
4. **少額決済**: 小額の実 BTC を支払い、`/checkout/success` に戻る。
5. **受取確認**: 支払い先アドレスが **Sparrow** に着金（ウォッチオンリーで検知）。
6. **Webhook**: BTCPay → Store → Webhooks → 配信ログが **HTTP 200**。
7. **DB**: Supabase `crypto_orders` に `status='paid'`（確定後）のレコードが入る。
8. **冪等性**: BTCPay の Webhook を手動 redeliver しても、レコードが重複せず更新されること。

---

## 10. 運用メモ

- **更新**: `cd /opt/btcpay/btcpayserver-docker && ./btcpay-update.sh`
- **バックアップ**: `./btcpay-backup.sh`（DB・設定。**シードは元々 BTCPay に無い**ため対象外＝Sparrow 側で管理）
- **監視**: BTCPay の通知、VPS のディスク使用量（プルーンドでも増加する）。
- **セキュリティ**: SSH 鍵認証のみ・root ログイン制限・自動更新の検討。

---

## 付録: 役割分担サマリ

| 主体 | 役割 |
|---|---|
| **Linux VPS** | BTCPay Server 本体（公開・常時稼働） |
| **Mac** | 開発・SSH 操作・Git 管理 |
| **iPhone** | BTCPay 管理画面の確認 |
| **Sparrow Wallet** | 秘密鍵・シードの保管／着金確認（BTCPay へは公開鍵のみ連携） |
| **Vercel** | EC サイト + サーバーレス API（インボイス作成・Webhook 受信） |
| **Supabase** | 注文の永続化（`crypto_orders`） |
