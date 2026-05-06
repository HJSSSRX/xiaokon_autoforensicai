---
tags: [openwrt, soft_router, openclash, proxy, firewall, port_forwarding, network_forensics, password_recovery]
tools: [mobaxterm, ssh, openwrt_web_ui, netstat]
category: network_forensics
difficulty: medium
source: 2024FIC_finals
date: 2026-05-05
verified: false
---
# Title: 2024FIC Finals - OpenWrt Soft Router Analysis (10 Questions)

## Problem
Analyze the OpenWrt soft router running inside PVE VM "Router" (100). Answer 10 questions about configuration, credentials, OpenClash proxy settings, and firewall rules.

## Evidence
- PVE VM 100 (Router) â€?OpenWrt soft router
- MobaXterm session records from PersonalPC

## Solution Steps

### Setup
1. Start VM 100 (Router) in PVE â€?shows OpenWrt boot screen
2. IP: 192.168.71.100 (matches MobaXterm session)
3. MobaXterm requires master password `mobapass00` to reveal saved credentials
4. Re-analyze with forensic tool after entering master password to see stored SSH passwords

### Q1: Soft router root password
After entering MobaXterm master password (mobapass00), forensic tool reveals stored SSH credentials.
â†?**OP2024fic**

### Q2: HTTP management panel port
```
netstat -antp
```
HTTP port visible, verify by accessing web UI.
â†?**8080**

### Q3: System version
Visible on OpenWrt login page or via `cat /etc/openwrt_release`.
â†?**23.05.2**

### Q4: WAN gateway
OpenWrt Web UI â†?Network â†?Routes.
â†?**192.168.71.2**

### Q5: Firewall port forwarding rule count
Network â†?Firewall â†?Port Forwards tab.
â†?**17**

### Q6: OpenClash control panel login key
Services â†?OpenClash â†?shows control panel login key.
â†?**MCoYZFwg**

### Q7: OpenClash LAN proxy password (SOCKS5/HTTP auth)
OpenClash â†?Override Settings â†?General Settings â†?scroll to bottom.
â†?**WAMqotI9**

### Q8: OpenClash subscription URL
OpenClash â†?Config Subscription.
â†?**https://www.amrth.cloud/s/FnT83dutLWlF5via?clash=2**

### Q9: "é¦™æ¸¯501 ä¸­ç»§ åŠ¨æ€? proxy node service port
OpenClash â†?Config Management â†?find node "é¦™æ¸¯501".
â†?**42001**

### Q10: opkg system image source config file absolute path
System â†?Software â†?opkg configuration.
â†?**/etc/opkg/distfeeds.conf**

## Key Takeaways
- **MobaXterm master password unlocks everything**: Password `mobapass00` from å¤‡å¿˜å½?reveals all stored SSH credentials
- **OpenWrt default management**: Usually on port 80, but here customized to 8080
- **OpenClash forensics**: Subscription URLs reveal VPN/proxy service usage; LAN proxy passwords show shared access
- **Port forwarding rules**: Critical for understanding how cloud phones are exposed externally
- **Soft router = PC-based router**: OpenWrt running in VM, managed via SSH and web UI
- **Nested analysis**: PVE VM â†?OpenWrt â†?forensic tool must support nested evidence

## Answer
Q1: OP2024fic
Q2: 8080
Q3: 23.05.2
Q4: 192.168.71.2
Q5: 17
Q6: MCoYZFwg
Q7: WAMqotI9
Q8: https://www.amrth.cloud/s/FnT83dutLWlF5via?clash=2
Q9: 42001
Q10: /etc/opkg/distfeeds.conf
