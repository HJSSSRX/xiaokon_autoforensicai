---
tags: [memory_forensics, volatility, windows, process_analysis, malware]
tools: [vol3, strings]
category: memory_forensics
difficulty: easy
source: example_demo
date: 2026-05-05
verified: true
---
# Windows Memory Analysis — Identify Suspicious Process

## Problem
Given a Windows 10 memory dump, identify a suspicious process and extract its executable.

## Solution Steps
1. Identify OS version
   ```
   vol3 -f memory.dmp windows.info
   ```
   → Windows 10 19041 x64

2. List all processes
   ```
   vol3 -f memory.dmp windows.pslist
   ```
   → Look for: abnormal PPID, unusual names, processes in wrong locations

3. Check process tree for parent-child anomalies
   ```
   vol3 -f memory.dmp windows.pstree
   ```
   → svchost.exe should have services.exe (PID ~600) as parent
   → cmd.exe spawned by explorer.exe is normal; by IIS w3wp.exe is suspicious

4. Check network connections
   ```
   vol3 -f memory.dmp windows.netscan
   ```
   → Look for: connections to external IPs, unusual ports, known C2 ports (4444, 8080, etc.)

5. Dump suspicious process
   ```
   vol3 -f memory.dmp windows.dumpfiles --pid {suspicious_pid}
   ```

6. Check strings for indicators
   ```
   strings dumped_file.exe | grep -iE "(http|https|cmd|powershell|base64)"
   ```

## Key Takeaways
- Always check PPID relationships — wrong parent is the #1 indicator
- svchost.exe should only be child of services.exe
- lsass.exe should only be child of wininit.exe
- Multiple instances of unique processes (lsass, csrss) are suspicious
- Network connections from system processes to external IPs are suspicious

## Answer
flag{example_not_real}
