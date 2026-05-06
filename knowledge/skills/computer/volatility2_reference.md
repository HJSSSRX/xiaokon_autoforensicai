# Volatility 2 — Windows Command Reference

> Source: Forensics-Wiki (forensics-wiki.com)

## Quick Reference Table
| Command | Description |
|---------|-------------|
| `imageinfo` | Identify OS profile |
| `pslist` | Active process list |
| `pstree` | Process tree view |
| `psscan` | Hidden/unlinked processes |
| `psxview` | Cross-reference process listings |
| `dlllist` | Loaded DLLs |
| `cmdscan` | CMD history |
| `consoles` | Console I/O history |
| `filescan` | Files in physical memory |
| `netscan` | Network artifacts (Vista+) |
| `connections` | TCP connections (XP/2003) |
| `connscan` | Terminated connections (XP/2003) |
| `sockets` | Listening sockets (XP/2003) |
| `hivelist` | Registry hive virtual addresses |
| `printkey` | Print registry key values |
| `hashdump` | Extract password hashes |
| `mimikatz` | Plaintext passwords |
| `malfind` | Detect injected code |
| `apihooks` | API hooks |
| `modules` | Loaded kernel drivers |
| `svcscan` | Running services |
| `clipboard` | Clipboard contents |
| `iehistory` | Browser history |
| `notepad` | Notepad contents |

## Process Analysis
```bash
# List all processes
vol.py -f {dump} --profile={profile} pslist

# Process tree
vol.py -f {dump} --profile={profile} pstree

# Scan for hidden processes (pool tag scanning)
vol.py -f {dump} --profile={profile} psscan

# DLLs loaded by a process
vol.py -f {dump} --profile={profile} dlllist -p {pid}

# Command line arguments
vol.py -f {dump} --profile={profile} cmdline

# CMD history (csrss.exe)
vol.py -f {dump} --profile={profile} cmdscan

# Process environment variables
vol.py -f {dump} --profile={profile} envars -p {pid}
```

## Memory Extraction
```bash
# Dump process memory
vol.py -f {dump} --profile={profile} memdump -p {pid} -D dump/

# Dump process executable
vol.py -f {dump} --profile={profile} procdump -p {pid} -D dump/

# Dump with --unsafe flag for malware with corrupted PE headers
vol.py -f {dump} --profile={profile} procdump -p {pid} -D dump/ --unsafe
```

## Network
```bash
# Vista+ : scan for network artifacts
vol.py -f {dump} --profile={profile} netscan

# XP/2003: active connections
vol.py -f {dump} --profile={profile} connections

# XP/2003: terminated connections
vol.py -f {dump} --profile={profile} connscan

# XP/2003: listening sockets
vol.py -f {dump} --profile={profile} sockets
```

## Registry
```bash
# List registry hives
vol.py -f {dump} --profile={profile} hivelist

# Print specific key
vol.py -f {dump} --profile={profile} printkey -K "Microsoft\Security Center\Svc"

# Dump all subkeys from a hive
vol.py -f {dump} --profile={profile} hivedump -o {hive_offset}

# Extract password hashes
vol.py -f {dump} --profile={profile} hashdump
```

## Malware Detection
```bash
# Find injected code (PE headers in non-image VADs)
vol.py -f {dump} --profile={profile} malfind

# Detect API hooks
vol.py -f {dump} --profile={profile} apihooks

# Cross-reference process listing methods to find discrepancies
vol.py -f {dump} --profile={profile} psxview
```

## File System
```bash
# Scan for file objects in memory
vol.py -f {dump} --profile={profile} filescan

# Extract files
vol.py -f {dump} --profile={profile} dumpfiles -Q {offset} -D dump/

# Parse MFT
vol.py -f {dump} --profile={profile} mftparser
```

## Tips
- 0 threads + 0 handles + non-empty exit time = process already terminated
- System and smss.exe have no Session ID (they start before sessions)
- `psscan` uses pool tag scanning → can find terminated/hidden processes that `pslist` misses
- `--memory` flag in procdump includes slack space between PE sections
- connscan can find terminated connections but may have false positives
