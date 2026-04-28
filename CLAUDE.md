# ForensicAI — Claude Code Configuration

Please read `AGENTS.md` first as the universal entry point.

## Claude Code Specific

- Use bash for all shell commands (prefer WSL if on Windows)
- When running forensic tools, write scripts to files first, then execute
- Avoid inline bash with complex quoting — write to .sh file instead
- Use `cat -n` for file preview to show line numbers
- Respect the 5-field answer format defined in `AI_BRAIN/output_contract.md`
