# BTCPay Server — Oracle Cloud「Always Free」構築手順（無料）

[`btcpay-vps-setup.md`](./btcpay-vps-setup.md) の **Oracle Cloud Always Free（ARM）版**。
無料枠で BTCPay（Bitcoin オンチェーン優先・プルーンド）を本番稼働させる。

> ⚠️ **お金を扱う注意**：Always Free は SLA なし・ARM 容量品薄・アイドル回収規定あり。
> 検証〜小規模運用には十分だが、集客が増えたら有料 VPS（Hetzner CPX21 等）への移行を推奨。
> BTCPay は `btcpay-backup.sh` / 設定エクスポートで移行可能。

---

## 0. Oracle 特有の「つまずき4点」（先に把握）
1. **ARM 容量エラー**：人気リージョンは `Out of host capacity`。→ リージョン選択・再試行で回避（§2）。
2. **二重ファイアウォール**：①VCN の Security List/NSG ②インスタンス内 iptables の **両方**で 80/443 を開ける（§6）。これを忘れると TLS 証明書取得が失敗する。
3. **ログインユーザーは `ubuntu`**（root ではない）：`ssh ubuntu@<IP>` → `sudo su -`。
4. **パブリック IP は確保（Reserved）推奨**：エフェメラルだと再作成時に変わり DNS がずれる。

---

## 1. アカウント作成
1. https://www.oracle.com/cloud/free/ → 「Start for free」
2. メール・国（Japan）・本人確認用 **クレジットカード**登録（**Always Free 分は課金されない**／本人確認のみ）
3. ホームリージョンを選択（後述の容量を考慮。日本なら **Japan East (Tokyo)** / **Japan Central (Osaka)**。混雑時は容量が出やすい別リージョンも検討）

---

## 2. ARM インスタンス作成（VM.Standard.A1.Flex）
コンソール → **Compute → Instances → Create instance**：

| 項目 | 値 |
|---|---|
| Name | `btcpay` |
| Image | **Canonical Ubuntu 22.04** |
| Shape | **Ampere → VM.Standard.A1.Flex** |
| OCPU / Memory | **2 OCPU / 12GB**（または 4 OCPU / 24GB。Always Free 上限内） |
| Boot volume | **100GB**（カスタムサイズ。無料はブロック合計 200GB まで） |
| SSH keys | **Paste public key** に下記を貼り付け |

**登録する公開鍵（既存の Mac の鍵）:**
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL6R0ora4zq61AxvRXuSsyqepQVl1QWKiG+5grXgCgcn seiren8788@github.com
```

### ARM 容量エラー（Out of host capacity）の回避
- 別の **Availability Domain**（AD-1/2/3）を試す。
- OCPU を **2/12GB** に下げると確保しやすい。
- 時間帯を変えて再試行（早朝など）。
- それでも出ない場合、ホームリージョンを容量のあるリージョンに変更（アカウント作成時のみ選択可の点に注意）。

作成後 → インスタンス詳細の **Public IP address** を控える。
（任意だが推奨）**Reserved Public IP** に変換：Networking → IP management で予約 IP を割当。

---

## 3. DNS 設定
Xserver Domain で A レコード：

| ホスト名 | 種別 | 値 |
|---|---|---|
| `btcpay` | A | Oracle のパブリック IP |

確認（Mac）:
```bash
dig +short btcpay.socialboost.jp   # → Oracle の IP が返ればOK
```

---

## 4. SSH 接続（Mac から）
Oracle の Ubuntu は **`ubuntu` ユーザー**でログイン：
```bash
ssh ubuntu@<OracleのIP>
sudo su -          # 以降 root で作業
```

---

## 5. ポート開放①：VCN Security List（クラウド側）
コンソール → **Networking → Virtual Cloud Networks → （対象VCN）→ Subnet → Security List** →
**Add Ingress Rules**：

| Source CIDR | IP Protocol | Dest Port |
|---|---|---|
| `0.0.0.0/0` | TCP | **80** |
| `0.0.0.0/0` | TCP | **443** |

（22/SSH は既定で開いている）

> NSG を使う構成なら、同じ 80/443 を NSG の Ingress に追加。

---

## 6. ポート開放②：インスタンス内 iptables（OS 側・Oracle 必須）
Oracle の Ubuntu イメージは **iptables で 80/443 を塞いでいる**ため、OS 側でも開ける：

```bash
# root で
iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
netfilter-persistent save     # 再起動後も保持
```
> ※ この OS 側 iptables を忘れると、Security List を開けても外部から 80/443 に届かず、**Let's Encrypt 証明書取得が失敗**する（Oracle で最頻出のハマりどころ）。

---

## 7. BTCPay インストール（BTC オンチェーン・Lightning なし）
**DNS 反映を確認してから**（§3）、root で実行：
```bash
mkdir -p /opt/btcpay && cd /opt/btcpay
git clone https://github.com/btcpayserver/btcpayserver-docker
cd btcpayserver-docker

export BTCPAY_HOST="btcpay.socialboost.jp"
export NBITCOIN_NETWORK="mainnet"
export BTCPAYGEN_CRYPTO1="btc"
export BTCPAYGEN_ADDITIONAL_FRAGMENTS="opt-save-storage-s"   # プルーンド ≒30GB
export BTCPAY_ENABLE_SSH=true
# Lightning は入れない（後日追加可）

. ./btcpay-setup.sh -i
```
完了後 `https://btcpay.socialboost.jp` で管理者登録。Bitcoin ノード同期を待つ。

---

## 8. 以降の設定（共通手順書を参照）
ウォレット接続（**Sparrow ウォッチオンリー / xpub・zpub・descriptor、シード非投入**）、Store ID、
API Key、Webhook、Vercel 環境変数、Supabase スキーマ、本番テストは
[`btcpay-vps-setup.md`](./btcpay-vps-setup.md) の §5〜§9 と同一。

---

## 9. Oracle Always Free 運用メモ
- **回収対象化を避ける**：BTCPay は常時稼働＝CPU/ネットワークに継続負荷があるため通常は対象外。停止放置しない。
- **ディスク監視**：プルーンドでも増える。`df -h` を時々確認。
- **再起動後**：iptables は `netfilter-persistent save` 済みなら保持。Docker コンテナは自動起動。
- **バックアップ**：`/opt/btcpay/btcpayserver-docker/btcpay-backup.sh`（シードは BTCPay に無いので対象外＝Sparrow 側で保管）。
- **移行**：有料 VPS へ移す場合はバックアップを新ホストで復元 → DNS を新 IP に向け替え。
