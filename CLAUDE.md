# AutoForensicAI

This is a digital forensics and security automation project powered by AI multi-agent coordination.

## Quick Start

When the user says **"小空自己动"**, read and follow the instructions in `prompts/main.md` to enter Main Designer mode.

## Project Structure

```
prompts/           — System prompts (main.md, role templates)
knowledge/
  solved/          — Verified solutions with searchable tags
  skills/          — Per-role skill files (techniques, tool usage)
  cards/           — Extracted knowledge cards from external sources
shared/            — Runtime cross-role coordination (findings, timeline, questions)
tools/             — Helper scripts (install, search, training)
```

## Key Rules

1. **Search before solving**: Run `python tools/kb_search.py --ask "{question}"` or `--tags` before starting any analysis
2. **CLI over MCP**: Use command-line tools directly (nmap, vol3, strings, tshark, sqlmap, etc.)
3. **Document everything**: Every session must produce a `knowledge/solved/*.md` file
4. **Coordinate via files**: Use `shared/` directory for multi-agent communication
5. **Consultant mode**: User can ask forensics/security questions anytime — search KB and answer from existing knowledge
