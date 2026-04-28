# Tool Registry

Structured YAML files describing each forensic tool's installation, usage, and compatibility.

## Format

Each tool is described in a YAML file: `<tool_name>.yaml`

See `share/SYSTEM_DESIGN.md` §3.3 for the full schema.

## Status

Tool registry is being populated. Priority tools to document:
- Zimmerman suite (RECmd, MFTECmd, EvtxECmd, PECmd, etc.)
- sleuthkit (mmls, fls, icat, tsk_recover)
- sqlite3
- jadx
- radare2/r2
- volatility3
- exiftool
- hashcat/john
