# DVWA SQLi — Avoid 302 Redirects & Run sqlmap (GitHub-ready)

**Purpose:** Short, copy‑and‑pasteable guide that fixes the `HTTP/1.1 302 Found -> ../../login.php` problem, shows how to confirm a working session, and runs `sqlmap` reliably. Save this file in your GitHub repo (e.g., `DVWA_SQLi_302_Fix_and_SQLMap_Guide.md`) and copy commands directly into your VM terminal.

> **Safety:** Only run these commands against your own DVWA VM or another explicitly authorized lab environment.

---

## How to use
- Open the file in GitHub and copy commands one line at a time into your Kali VM terminal. Do not paste big multi‑line blocks at once unless the block is explicitly a single command.

---

## Quick overview (what this does)
- Recreates a fresh logged‑in terminal session (cookies.txt)
- Forces DVWA `security=low` for that session
- Tests the vulnerable page using the same cookie and browser User‑Agent
- Runs `sqlmap` with the exact cookie and UA so the server will accept the requests

---

## 1. Start from your home directory
```bash
cd ~
pwd
```

---

## 2. Create a fresh logged-in cookie file and set security=low
```bash
rm -f ~/cookies.txt
curl -s -c ~/cookies.txt -d "username=admin&password=password&Login=Login" "http://127.0.0.1/dvwa/login.php" > /dev/null
curl -s -b ~/cookies.txt -c ~/cookies.txt -d "security=low&seclev_submit=Submit" "http://127.0.0.1/dvwa/security.php" > /dev/null
```
**Expected:** `~/cookies.txt` exists and contains `PHPSESSID` and `security` with value `low`.

Check it:
```bash
sed -n '1,200p' ~/cookies.txt
```

---

## 3. Test the vulnerable page using the same cookie & browser UA
1. In your browser copy the `User-Agent` (open DevTools console and run `navigator.userAgent`) and the `PHPSESSID` from Application → Cookies for `127.0.0.1` (if you already used curl, you can get `PHPSESSID` from `cookies.txt`).

2. Run this (replace placeholders accordingly):
```bash
# If you used curl to create cookies, extract the session automatically
SESSION=$(awk '/PHPSESSID/ {print $7; exit}' ~/cookies.txt); echo "SESSION=$SESSION"
# Replace USER_AGENT with the string you copied from the browser (keep quotes)
USER_AGENT='PASTE_BROWSER_USER_AGENT_HERE'

# Test the page using that cookie + UA
curl -s -I --cookie "PHPSESSID=${SESSION}; security=low" -A "$USER_AGENT" \
  "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" | sed -n '1,12p'
```
**Expected:** `HTTP/1.1 200 OK` (or at least not `302 -> ../../login.php`). If you still get `302`, continue to the Troubleshooting section.

---

## 4. Run sqlmap using the exact cookie & UA (when you get 200 OK)
```bash
# Use the same SESSION and USER_AGENT from step 3
sqlmap -u "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=${SESSION}; security=low" --user-agent="$USER_AGENT" \
  -p id --batch --level=3 --risk=2 --dbs | tee sqlmap-dbs.txt
```
If `sqlmap` reports `not injectable`, try aggressive mode:
```bash
sqlmap -u "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=${SESSION}; security=low" --user-agent="$USER_AGENT" \
  -p id --batch --level=5 --risk=3 --technique=BEU --random-agent --tamper=space2comment --dbs | tee sqlmap-aggr.txt
```

---

## Troubleshooting — step-by-step checks
If you still see `302` after using the browser `PHPSESSID` + UA, run these diagnostics and fix steps.

### A) Confirm DVWA database/tables exist
```bash
mysql -u dvwauser -p -D dvwa -e "SHOW TABLES;"
# (enter dvwapass or your configured password)
```
- **Expected:** a list of tables: `users`, `guestbook`, etc. If you get an error or no tables, open `http://127.0.0.1/dvwa/setup.php` in your browser and click **Create / Reset Database**.

### B) Check PHP session save path and permissions
```bash
php -i | grep session.save_path -n
ls -ld /var/lib/php/sessions 2>/dev/null || ls -ld /tmp
stat -c '%U %G %a %n' /var/lib/php/sessions 2>/dev/null || true
```
- **Expected:** session save path exists and is owned by `www-data:www-data` with mode `1733`. If not, fix with:
```bash
sudo mkdir -p /var/lib/php/sessions
sudo chown -R www-data:www-data /var/lib/php/sessions
sudo chmod 1733 /var/lib/php/sessions
sudo systemctl restart apache2
```
Then re-create cookies and re-test (Steps 2–3).

### C) If DVWA forces `security=impossible` server-side
Check config for default security value and change it:
```bash
sudo grep -n "default_security" /var/www/html/dvwa/config/config.inc.php* 2>/dev/null || true
sudo cp /var/www/html/dvwa/config/config.inc.php /var/www/html/dvwa/config/config.inc.php.bak
sudo nano /var/www/html/dvwa/config/config.inc.php
# set default to 'low' where appropriate, save and exit
sudo systemctl restart apache2
```

### D) Inspect server behavior (see Set-Cookie headers)
```bash
curl -v --cookie "PHPSESSID=${SESSION}; security=low" -A "$USER_AGENT" \
  "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" 2>&1 | sed -n '1,200p'
```
- Look for `Set-Cookie:` lines. If server sets `security=impossible`, change default in config (step C) or use browser cookie+UA.

---

## Extra: Single diagnostic block (run if you want me to debug for you)
Copy & paste everything the following prints (it contains cookie file preview, curl test, and last Apache errors):
```bash
SESSION=$(awk '/PHPSESSID/ {print $7; exit}' ~/cookies.txt); USER_AGENT='PASTE_BROWSER_UA'; 

echo "SESSION=$SESSION"; sed -n '1,200p' ~/cookies.txt; 

curl -s -I --cookie "PHPSESSID=${SESSION}; security=low" -A "$USER_AGENT" \
  "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" | sed -n '1,16p'; 

sudo tail -n 60 /var/log/apache2/error.log
```

Paste the full output here and I will tell you the **single** next command to run.

---

## Upload to GitHub
1. Save this file as `DVWA_SQLi_302_Fix_and_SQLMap_Guide.md`.  
2. In your repo folder:
```bash
git add DVWA_SQLi_302_Fix_and_SQLMap_Guide.md
git commit -m "Add DVWA SQLi 302 fix & sqlmap guide"
git push
```

---

## Final notes
- The browser cookie + exact browser UA approach resolves session acceptance problems in most lab setups. If that fails, the diagnostic block will quickly show whether it’s a DB, PHP session, or config issue. Paste the diagnostic output and I will give the **single** command you need to run next.


---

**End of guide**
