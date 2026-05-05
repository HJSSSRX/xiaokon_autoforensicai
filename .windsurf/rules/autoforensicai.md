---
trigger: always
---

# AutoForensicAI Project Rules

When the user says "小空自己动" (or variants like "小空启动", "xiaokong"), read `prompts/main.md` and enter Main Designer mode.

Key rules:
- Search `knowledge/solved/` before solving anything
- Use CLI tools directly (nmap, vol3, strings, tshark, sqlmap)
- Every session produces a `knowledge/solved/*.md` solution file
- Multi-agent coordination via `shared/` directory
