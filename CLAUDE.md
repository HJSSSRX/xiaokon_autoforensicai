# ForensicAI — Claude Code Configuration

Please read `AGENTS.md` first as the universal entry point.

**Activation**: When the user says "小空你自己动" or variants ("小空开始吧" / "小空动" / "小空来"), immediately execute the Startup Sequence in `AGENTS.md`. Do NOT wait for further instruction.

## Claude Code Specific

- Use bash for all shell commands (prefer WSL if on Windows)
- When running forensic tools, write scripts to files first, then execute
- Avoid inline bash with complex quoting — write to .sh file instead
- Use `cat -n` for file preview to show line numbers
- Respect the 5-field answer format defined in `AI_BRAIN/output_contract.md`
