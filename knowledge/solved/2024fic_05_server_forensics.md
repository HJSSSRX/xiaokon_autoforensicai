---
tags: [server_forensics, linux, mysql, docker, nginx, spring_boot, java, bcrypt, password_bypass, openeuler, ubuntu, website_reconstruction, jar_decompile]
tools: [docker, mysql, ssh, jadx, nginx, qm, fsck, nmcli, passwd]
category: server_forensics
difficulty: hard
source: 2024FIC_finals
date: 2026-05-05
verified: false
---
# Title: 2024FIC Finals - Server Forensics & Website Reconstruction (14 Questions)

## Problem
Analyze server cluster VMs in PVE: VM 111 (Java web server, Ubuntu), VM 112 (SQL database server, openEuler), and an nginx LXC container. Reconstruct the "È≤∏ÊòìÂÖÉMALLÁÆ°ÁêÜÁ≥ªÁªü" website. Answer 14 questions.

## Evidence
- PVE VM 111 ‚Ä?Java/Spring Boot web application server (Ubuntu)
- PVE VM 112 (sqlserver) ‚Ä?MySQL database in Docker (openEuler)
- LXC container 110 ‚Ä?nginx reverse proxy
- Virtual disk images inside PVE data partition

## Solution Steps

### Setup: Extract and hash VM disk
Download `/mnt/pve/local2/images/112/vm-112-disk-0.qcow2` via SSH.
**Important**: Do NOT start VM 112 before extracting ‚Ä?running it modifies the disk and changes hash.

### Q1: VM 112 virtual disk SHA256
```
SHA256(vm-112-disk-0.qcow2) = 0a7d9f77a5903bece9290f364b410a233a8415dabb35bc1ef585d837681d44e3
```
‚Ü?**0a7d9f77a5903bece9290f364b410a233a8415dabb35bc1ef585d837681d44e3**

### Q2: Database server root password encryption method
A.SM3 B.SHA256 C.MD5 D.Bcrypt
Check `/etc/shadow` in VM 112 image. Hash prefix indicates SM3.
‚Ü?**A. SM3**

### Q3: Database server kernel version
Check via forensic tool system info or `uname -r`.
‚Ü?*(visible in forensic tool analysis)*

### Q4: Java server web service port (multiple choice)
A.9030 B.9031 C.9032 D.9033
Extract jar files from VM 111. Decompile `jinyi.web.web.jar` with Jadx, check prod profile:
- web port: 9032
- api port: 9031
‚Ü?**BC** (9031, 9032)

### Q5: Docker container count in VM 112
Check forensic tool Docker analysis.
‚Ü?**2**

### Q6: MySQL container ID first 6 chars
Visible in forensic tool Docker container list.
‚Ü?**3ba5cb**

### Q7: MySQL version in container
Check via forensic tool or `mysql --version`.
‚Ü?**5.7.44**

### Q8: External domain for admin backend (multiple choice)
A.jy.proxy2.jshcloud.cn B.master.jy.proxy2.jshcloud.cn C.jy.proxy.jshcloud.cn D.master.jy.proxy.jshcloud.cn
Enter nginx LXC container: `lxc-attach 110`, check `/etc/nginx/conf.d/*.conf`.
Config shows admin backend on `master.jy.proxy2.jshcloud.cn` and `master.jy.proxy.jshcloud.cn`.
‚Ü?**BD**

### Q9: Website framework
Check `MANIFEST.MF` in jar file via Jadx.
‚Ü?**B. SPRING_BOOT**

### Q10: Number of database types used
Prod config shows mysql + redis.
‚Ü?**2**

### Q11: MySQL password in prod environment
From application-prod.yml in decompiled jar.
‚Ü?**honglian7001**

### Q12: Aliyun OSS secret key
Search for "aliyun" or "oss" in decompiled jar config files.
‚Ü?*(found in application config)*

### Q13: Admin password encryption method
Connect to MySQL database, check `sys_user` table. Admin password hash format indicates Bcrypt.
‚Ü?**Bcrypt**

### Q14: Admin phone number
Same `sys_user` table in MySQL.
‚Ü?**15888888888**

### Password Bypass Procedures

#### Ubuntu (VM 111) bypass:
1. At GRUB, press `e`
2. Find `linux` line, change `ro` to `rw single init=/bin/bash`
3. Press Ctrl+X to boot
4. Run `passwd` to change password
5. Fix SSH: uncomment `PasswordAuthentication yes` in `/etc/ssh/sshd_config`

#### openEuler (VM 112) bypass:
1. At GRUB, press `e`, enter default password: `root / openEuler#12`
2. Find `linux` line, change `ro` to `rw`, add `init=/bin/sh`
3. Press Ctrl+X
4. Run `passwd` to change password
5. Run `touch /.autorelabel` to persist password across reboots
6. Fix network: rename ifcfg file or bind interface
```
nmcli connection modify ens36 connection.interface-name enp6s18
nmcli connection reload
```

### Website Reconstruction:
1. Start VMs 111 + 112 (reduce vCPU first)
2. Start Docker containers in 112: `docker start 3b 2a`
3. Start jar files in 111:
```
java -jar /home/service/jinyi/api/jinyi.api.api-1.0.0.jar --spring.profiles.active=prod
java -jar /home/service/jinyi/web/jinyi.api.api-1.0.0.jar --spring.profiles.active=prod
```
4. Add hosts entries for domains ‚Ü?PVE nginx IP
5. Replace admin Bcrypt hash in MySQL with known hash (e.g., Bcrypt of "123456")
6. Login to admin backend

## Key Takeaways
- **Disk hash BEFORE boot**: Always extract virtual disk images before starting VMs ‚Ä?running modifies the disk
- **GRUB password bypass**: Works for both Ubuntu and openEuler with slightly different procedures
- **openEuler default GRUB password**: `root / openEuler#12`
- **Network interface mismatch**: Config says `ens36` but physical device is `enp6s18` ‚Ä?use `nmcli` to bind
- **JAR decompilation**: Jadx reveals Spring Boot configs including database credentials, API keys
- **Bcrypt password replacement**: Replace hash in database to login to admin panel
- **MySQL port 13306**: Non-standard port ‚Ä?check Docker port mapping
- **nginx LXC container**: Use `lxc-attach <id>` to enter without password

## Answer
Q1: 0a7d9f77a5903bece9290f364b410a233a8415dabb35bc1ef585d837681d44e3
Q2: A (SM3)
Q3: (from forensic tool)
Q4: BC (9031, 9032)
Q5: 2
Q6: 3ba5cb
Q7: 5.7.44
Q8: BD
Q9: B (SPRING_BOOT)
Q10: 2
Q11: honglian7001
Q12: (from jar config)
Q13: Bcrypt
Q14: 15888888888
