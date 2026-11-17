<p align="center"><a href="README.md">English</a> · <b>فارسی</b></p>

<div dir="rtl">

# Backpack-Railway

تونل **BackPack** و پنل **3x-ui** را با چند کلیک روی **Railway** بالا بیاور: پروژه را **Fork** کن، Fork خودت را در Railway دیپلوی کن، لینک راه‌اندازی تونل را در یک متغیر بگذار. تمام.

> Based on BackPack by Amin Mohammadi (AminMGMT)
> https://github.com/AminMGMT/BackPack

این مخزن **غیررسمی** است و خودش BackPack نیست؛ هنگام build فقط باینری رسمی BackPack را دانلود و با چک‌سام تأیید می‌کند. 3x-ui هم از ایمیج رسمی `ghcr.io/mhsanaei/3x-ui` می‌آید. ([لایسنس و اعتبار](#لایسنس-و-اعتبار))

## فهرست

- [این پروژه چه کار می‌کند؟](#این-پروژه-چه-کار-میکند)
- [نصب در ۵ قدم](#نصب-در-۵-قدم)
- [آپدیت کردن Fork](#آپدیت-کردن-fork)
- [متغیرها](#متغیرها)
- [تنظیم پورت‌ها](#تنظیم-پورتها)
- [ماندگاری داده‌ها](#ماندگاری-دادهها)
- [امنیت](#امنیت)
- [عیب‌یابی](#عیبیابی)
- [جزئیات فنی](#جزئیات-فنی)
- [لایسنس و اعتبار](#لایسنس-و-اعتبار)

---

## این پروژه چه کار می‌کند؟

BackPack یک تونل بین **سرور ایران** و **سرور خارج** است. اینجا سرور خارج همین کانتینر Railway است. روی سرور ایران یک **Setup Link** (`backpack://…`) می‌گیری و آن را به Railway می‌دهی؛ کانتینر خودش به ایران وصل می‌شود و تونل را بالا نگه می‌دارد. چون کانتینر خودش اتصال را شروع می‌کند، Railway لازم نیست هیچ پورتی برای تونل باز کند.

داخل کانتینر چهار چیز اجرا می‌شود:

| چیز | کارش |
|---|---|
| تونل BackPack | از روی `TUNNEL_LINK` ساخته می‌شود و ترافیک را به inboundهای 3x-ui می‌رساند |
| 3x-ui | پنل ساخت inbound (VLESS، VMess و …)، پورت `2053` |
| پنل وب BackPack | وضعیت و لاگ تونل، پورت `7777`، فقط زیر یک مسیر محرمانه |
| watchdog BackPack | تونلی که قطع شود را دوباره بالا می‌آورد |

</div>

```text
 User ─▶ Iran server :443
               ▲
               ║  BackPack tunnel — the Railway container dials OUT to Iran
               ▼
 Railway container ─▶ 127.0.0.1:<port> ─▶ x-ui inbound
```

<div dir="rtl">

---

## نصب در ۵ قدم

1. **Fork** کن.
2. روی **سرور ایران** تونل را بساز و **Setup Link** را بردار.
3. در **Railway** از Fork خودت دیپلوی کن.
4. در **Variables** لینک و رمز پنل را بگذار.
5. **دامنه** بساز، لاگ را بخوان و در 3x-ui یک inbound بساز.

### ۱. پروژه را Fork کن

در بالای صفحهٔ همین مخزن در GitHub روی **Fork** و بعد **Create fork** بزن. از این به بعد با Fork خودت کار می‌کنی.

> **هیچ لینک، رمز یا توکنی را داخل فایل‌های Fork ننویس.** Fork یک مخزن عمومی، عمومی است. همهٔ مقدارهای محرمانه فقط در **Railway ← Variables** می‌روند.

### ۲. تونل را روی سرور ایران بساز

اگر BackPack روی سرور ایران نصب نیست:

</div>

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AminMGMT/BackPack/main/install.sh)
```

<div dir="rtl">

بعد منو را باز کن:

</div>

```bash
sudo backpack
```

<div dir="rtl">

و این مسیر را برو (بقیهٔ سؤال‌ها را با Enter و مقدار پیش‌فرض رد کن):

</div>

```text
1. Setup Iran
→ Reverse
→ Transport            برای شروع TCP یا TCP Mux
→ Iran IP Or Domain    آدرسی که Railway باید به آن وصل شود
→ Tunnel Port          مثلاً 3002
→ Forwarded Ports      مثلاً 443=127.0.0.1:2096   (بخش «تنظیم پورت‌ها»)
→ Tunnel Name
→ Security Token       خودکار ساخته می‌شود؛ Enter
→ How Should The Tunnel Be Tuned?   Turbo
```

<div dir="rtl">

در خلاصهٔ آخر، زیر **Setup Link** یک خط `backpack://…` می‌بینی؛ آن را **کامل** کپی کن. بعد در فایروال ایران پورت تونل و پورت‌های فورواردشده را باز کن:

</div>

```bash
ufw allow 3002/tcp     # پورت تونل (برای تونل‌های UDP مثل KCP: /udp)
ufw allow 443/tcp      # پورتی که کاربرها به آن وصل می‌شوند
```

<div dir="rtl">

بعداً هم لینک را از `sudo backpack` ← `Manage` ← `Setup Link` می‌توانی دوباره بگیری.

**کدام ترنسپورت؟** TCP و TCP Mux برای شروع خوب‌اند؛ TCP + Stealth، WS/WSS و UDP + KCP + FEC هم روی Railway کار می‌کنند. **PCK** (به `iptables` و دسترسی raw نیاز دارد) و تونل‌های **Direct** (ایران باید به خارج وصل شود) روی Railway کار نمی‌کنند. راهنمای انتخاب: [Choosing a transport](https://github.com/AminMGMT/BackPack/blob/main/docs/choosing-a-transport.md).

### ۳. در Railway از Fork دیپلوی کن

1. در [railway.com](https://railway.com) وارد شو و **New Project ← Deploy from GitHub repo** را بزن.
2. اگر Fork خودت در لیست نبود، **Configure GitHub App** را بزن و به Railway اجازهٔ دیدن آن را بده.
3. Fork خودت (`<نام-کاربری>/Backpack-Railway`) را انتخاب کن. Railway خودش `Dockerfile` را پیدا و build می‌کند؛ چند دقیقه طول می‌کشد.

### ۴. متغیرها را بگذار

سرویس را باز کن ← تب **Variables** ← **Raw Editor** و این سه خط را (با مقدار خودت) بچسبان:

</div>

```env
TUNNEL_LINK=backpack://PASTE-THE-FULL-LINK-HERE
PANEL_PATH=k7Hq2mVx9TnPaw
PANEL_PASSWORD=choose-a-strong-password
```

<div dir="rtl">

`TUNNEL_LINK` همان لینک کامل قدم ۲ است. `PANEL_PATH` مسیر محرمانهٔ پنل BackPack است (۸ تا ۶۴ حرف انگلیسی، عدد، `_` یا `-`) و `PANEL_PASSWORD` رمز آن (حداقل ۸ کاراکتر). **Deploy** که بزنی، سرویس با مقدارهای جدید دوباره بالا می‌آید.

### ۵. دامنه بساز و کار را چک کن

**Settings ← Networking ← Generate Domain**؛ وقتی پورت را پرسید `7777` را بنویس. (هر سرویس Railway یک دامنه با یک پورت مقصد دارد؛ برای دیدن پنل 3x-ui همین عدد را `2053` کن.) **Replicas را روی ۱ نگه دار**؛ دو کانتینر با یک توکن یکدیگر را از تونل بیرون می‌اندازند.

در **Deployments ← View Logs** باید این خط‌ها را ببینی:

</div>

```text
[panel] web panel on port 7777 under /k7Hq2mVx9TnPaw/ (anything outside that path answers 404)
[tunnel-setup] Applying the setup link from TUNNEL_LINK...
[tunnel-setup] Tunnel is up and connected.
```

<div dir="rtl">

اگر به‌جای خط آخر این آمد، خطا نیست؛ تونل ساخته شده و خودش دوباره تلاش می‌کند وصل شود (علت‌های احتمالی در [عیب‌یابی](#عیبیابی)):

</div>

```text
[tunnel-setup] Tunnel is running but has not connected yet; supervisord keeps it running and it keeps retrying on its own.
```

<div dir="rtl">

حالا:

- **پنل BackPack:** `https://<دامنه-railway>/<PANEL_PATH>/` را باز کن و با `PANEL_PASSWORD` وارد شو. (آدرس بدون مسیر عمداً `404` می‌دهد.)
- **3x-ui:** Target Port دامنه را موقتاً `2053` کن و `https://<دامنه-railway>/` را باز کن. اول‌بار نام کاربری و رمز هر دو `admin` است؛ **همان لحظه عوضشان کن.** یک **inbound** بساز که **پورتش دقیقاً همان پورتی باشد که در Forwarded Ports ایران نوشتی** (در مثال `2096`). تونل ترافیک را به `127.0.0.1:2096` داخل کانتینر می‌رساند، و اگر آنجا چیزی گوش ندهد لاگ می‌نویسد `nothing is listening on 127.0.0.1:2096 on THIS server`.
- **کلاینت:** در کانفیگ کاربر **آی‌پی سرور ایران** و **پورت بیرونی** (مثلاً `443`) را بگذار، نه آدرس Railway.

---

## آپدیت کردن Fork

وقتی این مخزن تغییر کرد: در صفحهٔ Fork خودت **Sync fork ← Update branch** را بزن. Railway به‌صورت پیش‌فرض با هر commit جدید دوباره build و دیپلوی می‌کند.

BackPack را هم هر بار که build شود، آخرین ریلیز رسمی می‌گیرد. اگر می‌خواهی روی یک ورژن بماند، در Variables بنویس `BACKPACK_VERSION=v1.8.5` (ورژن آزمایش‌شدهٔ این پروژه). اگر Railway این متغیر را به build نرساند، مقدار پیش‌فرض `ARG BACKPACK_VERSION` را در `Dockerfile` Fork خودت عوض کن.

---

## متغیرها

همه در **Railway ← Variables** تنظیم می‌شوند.

| متغیر | الزامی؟ | پیش‌فرض | توضیح |
|---|---|---|---|
| `TUNNEL_LINK` | برای ساخت تونل | خالی | Setup Link کامل `backpack://…`. خالی باشد، تونل ساخته نمی‌شود. **توکن تونل داخل آن است؛ محرمانه نگهش دار.** |
| `TUNNEL_NAME` | نه | نام پیشنهادی لینک | نام تونل را عوض می‌کند |
| `TUNNEL_HOST` | نه | خالی | آدرس سرور ایران؛ فقط اگر لینک آن را ندارد |
| `PANEL_PATH` | توصیه می‌شود | تصادفی | مسیر محرمانهٔ پنل BackPack، ۸ تا ۶۴ کاراکتر از `A-Z a-z 0-9 _ -` |
| `PANEL_PASSWORD` | توصیه می‌شود | تصادفی | رمز پنل BackPack، ۸ تا ۱۲۸ کاراکتر |
| `PANEL_PORT` | نه | `7777` | پورت پنل BackPack. Target Port دامنه باید همین باشد |
| `BACKPACK_VERSION` | نه | `latest` | ورژن BackPack برای build، مثلاً `v1.8.5` |

- مقدار نامعتبر `PANEL_*` نادیده گرفته می‌شود و دلیلش در لاگ می‌آید.
- اگر `PANEL_PATH` یا `PANEL_PASSWORD` را نگذاری، **با هر دیپلوی مقدار تازه‌ای** ساخته می‌شود و فقط یک بار در لاگ (بین دو خط `=====`) چاپ می‌شود.
- با هر دیپلوی فایل‌سیستم کانتینر از نو ساخته می‌شود و تونل از روی `TUNNEL_LINK` دوباره ساخته می‌شود. اگر روی سرور ایران چیزی را عوض کردی (پورت‌ها، ترنسپورت)، لینک تازه را از `Manage ← Setup Link` بگیر، در `TUNNEL_LINK` بگذار و دوباره دیپلوی کن.

---

## تنظیم پورت‌ها

در ایران، **Forwarded Ports** مشخص می‌کند هر پورت بیرونی به کدام پورت **داخل کانتینر** برود:

| ورودی | معنی |
|---|---|
| `443=127.0.0.1:2096` | کاربر به ایران:`443` وصل شود، تونل به `127.0.0.1:2096` کانتینر برساند |
| `443=127.0.0.1:2096, 8443=127.0.0.1:2097` | چند inbound با یک تونل |
| `443=127.0.0.1:2096\|127.0.0.1:2097` | دو backend با بالانس و health check |
| `10000-10009` | بازه؛ هر پورت به همان پورت |

> **`443` تنها یعنی «هر پورتی» نیست.** یعنی باید چیزی واقعاً روی `127.0.0.1:443` داخل کانتینر گوش بدهد. اگر inbound روی `2096` است، بنویس `443=127.0.0.1:2096`.

- پورت inbound نباید `2053` (3x-ui) یا `7777` (پنل BackPack) باشد.
- اگر inbound به **UDP** نیاز دارد: در ایران `Manage ← Edit ← Forward UDP` را روشن کن و `ufw allow <port>/udp` را بزن.
- برای **آی‌پی واقعی کاربر**: اول در inbound گزینهٔ **Accept Proxy Protocol** را روشن کن، بعد در ایران `Manage ← Edit ← Real client IP`. ترتیب برعکس همهٔ اتصال‌ها را خراب می‌کند.
- پورت پنل ادمین (2053) را تونل نکن.

مرجع کامل: [Port mappings](https://github.com/AminMGMT/BackPack/blob/main/docs/port-mappings.md) و [Behind a panel](https://github.com/AminMGMT/BackPack/blob/main/tutorial/behind-a-panel.md).

---

## ماندگاری داده‌ها

فایل‌سیستم کانتینر Railway با هر دیپلوی از نو ساخته می‌شود:

| چیز | بعد از دیپلوی |
|---|---|
| تونل، مسیر و رمز پنل BackPack | سر جایش؛ از `TUNNEL_LINK` و `PANEL_*` ساخته می‌شوند |
| دیتابیس 3x-ui (inboundها، کاربران، رمز ادمین) | **پاک می‌شود**، مگر Volume بگذاری |
| تنظیمات داخل پنل BackPack (2FA، تلگرام) | پاک می‌شود |

برای نگه داشتن inboundها: روی بوم پروژه در Railway راست‌کلیک کن ← **Volume** (یا `Ctrl+K` و جستجوی Volume)، آن را به سرویس وصل کن و **Mount Path** را `/etc/x-ui` بگذار. فقط همین مسیر پیشنهاد می‌شود؛ Volume روی `/etc/backpack` آزمایش نشده است.

---

## امنیت

- **رمز 3x-ui را همان اول عوض کن** (اولین بار `admin` / `admin`). دامنهٔ Railway عمومی است و اسکن می‌شود. Web Base Path پنل را هم از تنظیمات 3x-ui می‌توانی عوض کنی.
- **`TUNNEL_LINK` را جایی غیر از Railway Variables ننویس** (نه در Fork، نه در چت، Issue یا لاگ). هر کس آن را داشته باشد می‌تواند به‌جای تو به سرور ایران وصل شود. اگر لو رفت، روی سرور ایران توکن را عوض کن و لینک تازه بگیر.
- پنل BackPack **زیر مسیر محرمانه است و هر چیز بیرون از آن `404` می‌دهد.** `PANEL_PATH` را مثل رمز تصادفی و بلند انتخاب کن. در **Settings ← Security** می‌توانی ورود دومرحله‌ای هم روشن کنی.
- بعد از ۵ رمز اشتباه، ورود ۱۰ دقیقه بسته می‌شود. پشت پروکسی Railway همهٔ بازدیدکننده‌ها یک آی‌پی دیده می‌شوند، پس چند تلاش اشتباه ممکن است همه را موقتاً قفل کند.
- گزینهٔ **HTTPS** داخل تنظیمات پنل BackPack را روشن نکن؛ پنل HTTP ساده سرو می‌کند و TLS را Railway می‌دهد.

---

## عیب‌یابی

| نشانه | علت و راه حل |
|---|---|
| آدرس Railway بدون مسیر `404` می‌دهد | عادی است. `https://<دامنه>/<PANEL_PATH>/` را بزن |
| `502` یا «Application failed to respond» | Target Port دامنه را `7777` (پنل BackPack) یا `2053` (3x-ui) کن؛ HTTPS پنل BackPack خاموش بماند؛ لاگ را ببین |
| به‌جای پنل BackPack صفحهٔ ورود 3x-ui می‌آید | Target Port روی `2053` است؛ `7777` کن |
| مسیر یا رمز پنل را نمی‌دانم | `PANEL_PATH` و `PANEL_PASSWORD` را در Variables بگذار و دوباره دیپلوی کن |
| «تعداد تلاش زیاد» | قفل ورود؛ ۱۰ دقیقه صبر کن |
| `PANEL_PATH ignored` یا `PANEL_PASSWORD ignored` | مقدار نامعتبر است؛ طول و کاراکترها را طبق [متغیرها](#متغیرها) درست کن |
| `TUNNEL_LINK is not set` | متغیر خالی است |
| `link apply failed (exit N)` | لینک ناقص یا خراب است. کل `backpack://…` را کپی کن یا از `Manage ← Setup Link` تازه بگیر |
| `Tunnel is running but has not connected yet` | فایروال ایران (پورت تونل؛ برای KCP پروتکل `udp`)، روشن بودن تونل در ایران، آدرس داخل لینک، یا فیلتر مسیر. در ایران `Manage ← Status` و `Health Check` را بزن |
| `nothing is listening on 127.0.0.1:<port> on THIS server` | تونل سالم است ولی inbound نداری. در 3x-ui روی همان پورت inbound بساز، یا در ایران `Manage ← Edit ← Change forwarded ports` را عوض کن و `TUNNEL_LINK` را به‌روز کن |
| تونل وصل است ولی کلاینت وصل نمی‌شود | پورت inbound درست نیست، UDP لازم است ولی روشن نیست، یا فایروال ایران بسته است ([تنظیم پورت‌ها](#تنظیم-پورتها)) |
| بعد از دیپلوی inboundها پریدند | Volume نداری ([ماندگاری داده‌ها](#ماندگاری-دادهها)) |
| هشدار `sysctl` در لاگ تونل | بی‌خطر است؛ کانتینر اجازهٔ تغییر پارامتر کرنل ندارد |

---

## جزئیات فنی

<details>
<summary>ساختار فایل‌ها</summary>

| فایل | کار |
|---|---|
| `Dockerfile` | از ایمیج 3x-ui شروع می‌کند، `supervisor bash curl gawk` را نصب می‌کند، باینری BackPack را دانلود و با `SHA256SUMS` تأیید و در `/usr/local/bin/backpack` نصب می‌کند و اسکریپت‌ها را کپی می‌کند |
| `entrypoint.sh` | دیتابیس 3x-ui و پورت `2053` را آماده می‌کند، `panel-config.sh` را اجرا می‌کند، بعد `exec supervisord` |
| `supervisord.conf` | برنامه‌ها: `x-ui`، `backpack-webui`، `backpack-monitor` و `tunnel-setup` (یک‌بار مصرف) |
| `panel-config.sh` | از `PANEL_*` فایل `/etc/backpack/webui.json` را می‌نویسد (اتمی، مجوز `0600`) و در نبودشان مقدار تصادفی می‌سازد |
| `apply-link.sh` | `backpack link apply` را با `TUNNEL_LINK` (و `TUNNEL_NAME`، `TUNNEL_HOST`) اجرا می‌کند. کد خروج `4` («ساخته شد ولی هنوز وصل نشده») را موفقیت حساب می‌کند |
| `fake_systemctl.sh` | جایگزین `systemctl` برای کانتینر بدون systemd |
| `fake_journalctl.sh` | جایگزین `journalctl`؛ لاگ‌ها را از `/var/log` می‌خواند تا صفحهٔ Logs پنل کار کند |

</details>

<details>
<summary>systemctl جعلی چطور کار می‌کند؟</summary>

BackPack سرویس‌هایش را با `systemctl` و `journalctl` مدیریت می‌کند و داخل کانتینر systemd نیست؛ پس همه‌چیز را supervisord اجرا می‌کند و این دو اسکریپت فرمان‌های BackPack را ترجمه می‌کنند:

- BackPack برای هر تونل `/etc/systemd/system/backpack-<name>.service` می‌نویسد. با `start`، `restart` یا `enable --now`، از روی `ExecStart` آن یک برنامهٔ supervisord در `/etc/supervisor/custom.d/<name>.conf` ساخته و همگام نگه داشته می‌شود.
- `is-active`، `is-enabled` و `show -p MainPID` از XML-RPC روی `/run/supervisord.sock` با `curl` جواب داده می‌شوند (چند میلی‌ثانیه به‌جای حدود ۱۰۰ میلی‌ثانیه برای `supervisorctl`)، چون پنل و watchdog مدام وضعیت می‌پرسند.
- `backpack-webui` و `backpack-monitor` برنامه‌های ثابت‌اند و فقط start/stop/restart می‌شوند. ری‌استارت پنل جدا از خود پنل (detached) اجرا می‌شود تا نیمه‌کاره نماند.
- `disable --now` روی تونلِ در حال حذف، فایل برنامه‌اش را هم پاک می‌کند تا با بوت بعدی برنگردد.
- لاگ‌ها حجم محدود دارند (۱ مگابایت برای هر فایل)، و فرمان‌های `systemctl` در `/var/log/fake_systemctl.log` ثبت می‌شوند.

اگر داخل کانتینر شل داری (`railway ssh`):

```bash
supervisorctl status
tail -n 50 /var/log/backpack-webui.log
tail -n 50 /var/log/backpack-monitor.log
tail -n 50 /var/log/backpack-<name>.log
tail -n 50 /var/log/fake_systemctl.log
```

</details>

<details>
<summary>اجرای محلی با Docker</summary>

```bash
git clone https://github.com/<نام-کاربری>/Backpack-Railway.git
cd Backpack-Railway

docker build -t backpack-railway .
# ورژن مشخص: docker build --build-arg BACKPACK_VERSION=v1.8.5 -t backpack-railway .

docker run --rm -it \
  -p 2053:2053 -p 7777:7777 \
  -e TUNNEL_LINK='backpack://...' \
  -e PANEL_PATH='k7Hq2mVx9TnPaw' \
  -e PANEL_PASSWORD='a-strong-password' \
  -v xui-data:/etc/x-ui \
  backpack-railway
```

بعد `http://localhost:7777/k7Hq2mVx9TnPaw/` پنل BackPack و `http://localhost:2053/` پنل 3x-ui است. ایمیج برای `amd64` و `arm64` ساخته می‌شود.

</details>

<details>
<summary>محدودیت‌ها</summary>

- **systemd ندارد.** هر قابلیتی که به systemd timer، cron، `ufw` یا `iptables` تکیه کند داخل کانتینر کار نمی‌کند یا بی‌اثر است؛ مثل PCK و «ری‌استارت زمان‌بندی‌شدهٔ هر N ساعت» (آن را روی `0` بگذار).
- **فایل‌سیستم موقتی است.** فقط چیزی که در متغیرها یا Volume باشد می‌ماند.
- **یک دامنه و یک Target Port** برای هر سرویس؛ هر لحظه یکی از دو پنل از بیرون دیده می‌شود. اگر پروژهٔ Railway تو TCP Proxy دارد، پورت دوم را هم می‌شود بیرون گذاشت، ولی آن مسیر بدون TLS است و برای پنل ادمین توصیه نمی‌شود.
- پنل BackPack در اصل برای سرور ایران نوشته شده؛ اینجا روی سمت خارج اجرا می‌شود و برای دیدن وضعیت و لاگ همین تونل مناسب است.
- تونل KCP روی Railway به یک سرور ایران وصل شده؛ ولی همهٔ ترنسپورت‌ها و قابلیت‌های BackPack در این کانتینر امتحان نشده‌اند.

</details>

---

## لایسنس و اعتبار

این مخزن BackPack و 3x-ui را بازتوزیع نمی‌کند؛ هنگام build از منبع رسمی‌شان می‌گیرد.

- **BackPack** از **امین محمدی (AminMGMT)** تحت **GNU Affero General Public License v3.0** منتشر شده: <https://github.com/AminMGMT/BackPack>. مجوز فقط برای کد است؛ نام «BackPack» و لوگویش متعلق به نویسنده است ([TRADEMARK](https://github.com/AminMGMT/BackPack/blob/main/TRADEMARK.md)) و به معنی رسمی بودن این مخزن نیست. گفتن اینکه این پروژه «بر پایهٔ BackPack است یا با آن سازگار است» آزاد است. خط زیر طبق [NOTICE](https://github.com/AminMGMT/BackPack/blob/main/NOTICE) باید بدون تغییر بماند (Forkها هم):

</div>

```text
Based on BackPack by Amin Mohammadi (AminMGMT)
https://github.com/AminMGMT/BackPack
```

<div dir="rtl">

- **3x-ui** از **MHSanaei** تحت GPL-3.0: <https://github.com/MHSanaei/3x-ui>.
- **supervisor** و **Alpine Linux** هم در ایمیج هستند و هر کدام لایسنس خودشان را دارند.
- بقیهٔ مستندات BackPack در [مخزن اصلی](https://github.com/AminMGMT/BackPack) است؛ هر صفحهٔ آنجا یک خلاصهٔ فارسی هم دارد.

</div>