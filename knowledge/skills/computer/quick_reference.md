# Computer Forensics — Quick Reference

## Volatility 3 (Memory Forensics)
```bash
vol3 -f {dump} windows.info              # OS version, build
vol3 -f {dump} windows.pslist            # Process list
vol3 -f {dump} windows.pstree            # Process tree
vol3 -f {dump} windows.netscan           # Network connections
vol3 -f {dump} windows.filescan          # Open files
vol3 -f {dump} windows.dumpfiles --pid {pid}  # Extract files from process
vol3 -f {dump} windows.malfind           # Detect injected code
vol3 -f {dump} windows.cmdline           # Command line arguments
vol3 -f {dump} windows.handles --pid {pid}    # Handles for a process
vol3 -f {dump} windows.registry.hivelist # Registry hive locations
vol3 -f {dump} windows.hashdump          # Extract password hashes
vol3 -f {dump} windows.envars --pid {pid}     # Environment variables
```

## Sleuth Kit (Disk Forensics)
```bash
mmls {image}                             # Partition layout
fls -r -o {offset} {image}              # File listing (recursive)
icat -o {offset} {image} {inode}        # Extract file by inode
blkcat -o {offset} {image} {block}      # Extract raw block
tsk_recover -o {offset} {image} {outdir} # Recover deleted files
```

## Windows Event Logs
```bash
# Chainsaw (fast, Sigma rules)
chainsaw hunt {evtx_dir} -s sigma/ --mapping mappings/sigma-event-logs-all.yml
chainsaw search {evtx_dir} -t "keyword"

# Hayabusa
hayabusa csv-timeline -d {evtx_dir} -o timeline.csv
hayabusa logon-summary -d {evtx_dir}
```

## Key Event IDs
- 4624: Successful logon
- 4625: Failed logon
- 4648: Explicit credentials (runas)
- 4672: Special privileges assigned
- 4688: Process creation
- 4698/4702: Scheduled task created/updated
- 7045: Service installed
- 1102: Audit log cleared

## Registry Analysis
```bash
regripper -r {hive} -a                   # All plugins for hive type
regripper -r NTUSER.DAT -p userassist    # UserAssist (program execution)
regripper -r SYSTEM -p compname          # Computer name
regripper -r SAM -p samparse             # User accounts
regripper -r SOFTWARE -p uninstall       # Installed programs
```
