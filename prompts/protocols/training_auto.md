# Full-Auto Training Protocol

## Purpose
Validate and improve the AutoForensicAI pipeline by solving challenges with KNOWN answers. The goal is not just to get the flag — it's to produce a high-quality, reusable solution file in knowledge/solved/.

## Workflow

### Step 1: Challenge Setup
Main receives:
- Challenge files (images, pcaps, binaries, etc.)
- Known answer/flag (for verification)
- Challenge description and category

Main creates workspace:
```
training/{date}_{challenge_name}/
├── shared/
├── challenge/          ← challenge files here
├── work/               ← solver's working directory
└── output/
    └── solution.md     ← final output
```

### Step 2: Knowledge Base Search (CRITICAL)
Before ANY solving attempt:
```bash
python tools/kb_search.py --tags {relevant_tags}
python tools/kb_search.py --text "{key_phrases}"
python tools/kb_search.py --tools {likely_tools}
```

If a relevant prior solution exists:
- Read it
- Attempt to follow the same approach
- Note whether it worked or needed adaptation
- This tests KB reusability

If no prior solution exists:
- Solve from scratch
- This fills a gap in the KB

### Step 3: Solve
The solver (single window or multiple) works through the challenge:
1. Identify challenge type
2. Apply relevant techniques from skills/
3. Execute CLI commands step by step
4. Document every command and its output
5. Find the flag

### Step 4: Verify
Compare found answer with known answer:
- Match → proceed to Step 5
- No match → log failure, analyze why, retry with different approach

### Step 5: Generate Solution File
Write to `knowledge/solved/{challenge_name}.md`:

```markdown
---
tags: [{tag1}, {tag2}, ...]
tools: [{tool1}, {tool2}, ...]
category: {category}
difficulty: {easy|medium|hard}
source: {where this challenge came from}
date: {today}
verified: true
---
# {Title}

## Problem
{Challenge description}

## Solution Steps
{Numbered steps with exact commands and expected output}

## Key Takeaways
{What's transferable to other challenges}

## Answer
{flag}
```

### Step 6: Pipeline Assessment
Log training metrics:
```yaml
# training/{date}_{name}/metrics.yaml
challenge: {name}
category: {category}
kb_search_hit: true/false     # Did KB have relevant prior art?
kb_solution_reused: true/false # Was a prior solution directly applicable?
solve_success: true/false
solve_time_seconds: {N}
tools_used: [...]
new_knowledge_generated: true  # Always true if solved
pipeline_notes: "..."          # Any issues with the pipeline itself
```

## Multi-Window Training
For efficiency, Main can set up multiple solvers working on different challenges simultaneously. Each solver is independent — they just need their own workspace directory. Main monitors progress and collects results.

```
training/batch_2026-05-05/
├── challenge_01/
│   ├── shared/
│   ├── challenge/
│   └── output/solution.md
├── challenge_02/
│   ├── shared/
│   ├── challenge/
│   └── output/solution.md
└── batch_report.md       ← Main compiles this
```

## What Makes Training Different from Competition
| Aspect | Training | Competition |
|---|---|---|
| Known answer | Yes | No |
| Time pressure | No | Yes |
| Goal | Build KB + validate pipeline | Find answers fast |
| KB search | Test if it helps | Use it to save time |
| Documentation | Thorough | Good enough |
| Retry on failure | Yes, with analysis | Move on if stuck |
