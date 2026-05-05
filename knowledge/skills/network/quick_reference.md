# Network Forensics — Quick Reference

## tshark Essentials
```bash
# Overview
tshark -r {pcap} -q -z conv,ip          # IP conversations
tshark -r {pcap} -q -z io,phs           # Protocol hierarchy
tshark -r {pcap} -q -z endpoints,ip     # Endpoints

# HTTP Analysis
tshark -r {pcap} -Y "http.request" -T fields -e frame.time -e ip.src -e http.host -e http.request.method -e http.request.uri
tshark -r {pcap} --export-objects http,{outdir}
tshark -r {pcap} -Y "http.response" -T fields -e http.response.code -e http.content_type

# DNS
tshark -r {pcap} -Y "dns.qry.name" -T fields -e ip.src -e dns.qry.name -e dns.a | sort -u

# Follow stream
tshark -r {pcap} -q -z follow,tcp,ascii,{stream_num}

# Credentials
tshark -r {pcap} -Y "ftp.request.command == USER || ftp.request.command == PASS" -T fields -e ftp.request.command -e ftp.request.arg
tshark -r {pcap} -Y "http.authorization" -T fields -e http.authorization

# Extract files
tshark -r {pcap} --export-objects http,exported/
tshark -r {pcap} --export-objects smb,exported/
tshark -r {pcap} --export-objects tftp,exported/

# Statistics
tshark -r {pcap} -q -z http,stat,         # HTTP stats
tshark -r {pcap} -q -z http,tree          # HTTP request tree
```

## Nmap
```bash
nmap -sV -sC {target}                    # Version + default scripts
nmap -sV -p- {target}                    # All ports
nmap -sU --top-ports 100 {target}        # UDP top ports
nmap --script vuln {target}              # Vulnerability scan
nmap -sV --script=http-enum {target}     # HTTP enumeration
```

## Suspicious Indicators
- DNS to unusual TLDs (.tk, .xyz, encoded subdomains)
- HTTP POST to external IPs with large payloads
- Periodic beaconing (regular intervals)
- Non-standard ports for standard protocols
- Base64 in HTTP parameters or DNS queries
- ICMP data exfiltration (check payload size)
