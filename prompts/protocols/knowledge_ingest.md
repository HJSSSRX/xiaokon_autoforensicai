# Knowledge Ingestion Protocol

## Purpose
Extract structured, reusable knowledge from external sources (URLs, documents, repos, writeups) and store it in the knowledge base.

## Supported Sources
- URLs (blog posts, tutorials, writeups)
- Markdown / text files
- PDF documents (text extraction)
- GitHub repositories (README + code analysis)
- Pasted text (user copies content directly)

## Extraction Workflow

### Step 1: Content Acquisition
Read the source material completely.

### Step 2: Identify Knowledge Items
For each distinct technique, tool usage, or insight:
1. Is this actionable? (Has specific commands/steps, not just theory)
2. Is this new? (Not already in KB — check with kb_search.py)
3. Is this relevant? (Forensics, security, CTF, or pentesting related)

Skip items that are purely theoretical with no practical application.

### Step 3: Structure as Knowledge Card
Write to `knowledge/cards/{descriptive_name}.md`:

```markdown
---
tags: [{relevant_tags}]
tools: [{tools_mentioned}]
category: {category}
source_url: "{original_url}"
source_title: "{article_title}"
date: {extraction_date}
quality: {1-5}
---
# {Descriptive Title}

## Summary
{One paragraph: what is this technique and when to use it}

## Steps
{Numbered steps with exact commands}

## Notes
{Any caveats, prerequisites, or related techniques}
```

### Step 4: Update Skills (if applicable)
If the knowledge significantly extends an existing skill area:
- Append to the relevant `knowledge/skills/{role}/quick_reference.md`
- Only add commands/techniques not already there

### Step 5: Deduplication Check
```bash
python tools/kb_search.py --text "{key technique name}"
```
If a very similar card already exists, either:
- Skip (if identical)
- Merge (if the new source adds value to existing card)

## Quality Scoring
- **5**: Complete step-by-step with verified commands
- **4**: Good commands but not personally verified
- **3**: Useful technique but missing some details
- **2**: General guidance without specific commands
- **1**: Vague reference, minimal practical value

Only ingest items scoring 3+.

## From WriteUp to Solved
If the source is a CTF writeup with a complete solution:
- Store as `knowledge/solved/{name}.md` (not cards/)
- Use the full solved format with tags, tools, steps, and answer
