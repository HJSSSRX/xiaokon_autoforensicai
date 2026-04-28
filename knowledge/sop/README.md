# SOP Scripts (Deterministic Standard Operating Procedures)

Deterministic step-by-step scripts for solving forensic questions.
These work with weak models (7B) or purely manual operation — no LLM reasoning required.

## Directory Structure

```
sop/
├─ windows_disk/          # Windows evidence SOPs
│   ├─ registry_analysis.md
│   ├─ network_config.md
│   └─ ...
├─ linux_server/          # Linux server SOPs
├─ mobile_android/        # Android phone SOPs
├─ network_traffic/       # Network traffic SOPs
├─ binary_reverse/        # Binary analysis SOPs
└─ README.md              # This file
```

## SOP Format

Each SOP follows this template:

```markdown
## Scenario: [what this SOP solves]

### Prerequisites
- [what must be ready before starting]

### Steps
1. [command with placeholders]
   - Expected output: [what you should see]
   - If different: [troubleshooting]
2. [next command]
   ...

### Output Template
Answer: {extracted_value}
Evidence: {file_path}
Verification: {cross_check_result}
```

## Dual-Mode Index

- **Mode A (RAG)**: Capable models use `knowledge/solved/` via FAISS vector search
- **Mode B (SOP)**: Weak models/humans use these scripts via keyword → category matching

See `share/SYSTEM_DESIGN.md` §3.4 for full design.
