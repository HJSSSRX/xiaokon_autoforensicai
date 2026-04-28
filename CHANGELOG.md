# Changelog

All notable changes to ForensicAI (小空自己动) will be documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/). Versioning: SemVer.

---

## [0.2.0] - 2026-04-28 — 架构重构

### Added
- `AGENTS.md` — universal AI agent entry point (agent-agnostic)
- `CLAUDE.md` — Claude Code adapter
- `.cursorrules` — Cursor IDE adapter
- `knowledge/taxonomy.yaml` — two-level forensic classification (7 categories, 40+ subcategories)
- `knowledge/solved/2026fic/` — structured question database (YAML format, 5 examples migrated)
  - C01.yaml, C05.yaml, M01.yaml, M02.yaml, I03.yaml
- `strategies/` — mode-specific strategy profiles
  - `competition_cloud_solo.yaml`
  - `competition_local_team.yaml`
  - `training_cloud_solo.yaml`
  - `education_local_solo.yaml`
- `share/SYSTEM_DESIGN.md` — full system design document
- `share/PROPOSAL.md` — project proposal for resource acquisition
- `share/SYSTEM_REVIEW.md` — FIC2026 performance analysis + competitor comparison
- `CHANGELOG.md` — this file

### Changed
- `README.md` — rewritten for new architecture, project codename "小空自己动"
- `.gitignore` — updated to include new directories

### Architecture Decisions
- **Offline-first**: all features must have an offline fallback
- **Model-agnostic**: support cloud API, local high-end (32B+), local low-end (7B)
- **Agent-agnostic**: AGENTS.md as single source of truth, adapters for each IDE
- **Dual-mode index**: RAG (for capable models) + deterministic SOP (for weak models/humans)
- **Train-execute split**: strong models produce knowledge, weak models consume it
- **Education-native**: every solved question includes teaching metadata

---

## [0.1.0] - 2026-04-25 — FIC2026 实战版

### Initial Release
- AI_BRAIN/ persistent memory system (persona, output_contract, solved_patterns, tool_inventory)
- PLAYBOOK.md methodology guide (Windows/Android/Linux/Network)
- SESSION_START.md session management (SOLO/COOP/TEAM modes)
- knowledge/ base (8 playbooks, 8 writeup indices, 4 competition profiles)
- scripts/ collection (80+ FIC2026-specific scripts)
- FIC2026 competition support files (launch configs, multi-window SOP)
- wp_batches/ with ~45 solved questions from FIC2026
- share/ distributable package (install scripts, quickstart guides)

### FIC2026 Results
- Final score: 367/600 (61.2%)
- AI runtime: ~1 hour, cost: ~$10
- AI independently solved ~33 questions, human corrected ~5, human added ~7
