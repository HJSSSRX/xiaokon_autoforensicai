#!/usr/bin/env python3
"""Knowledge Base search tool for AutoForensicAI.

Search knowledge/solved/ and knowledge/skills/ for relevant prior work.
Designed to be called by AI agents or humans via CLI.

Usage:
    python tools/kb_search.py --tags memory_forensics volatility
    python tools/kb_search.py --tools vol3 strings
    python tools/kb_search.py --text "process injection"
    python tools/kb_search.py --category web
    python tools/kb_search.py --ask "how to detect process injection in memory dump"
    python tools/kb_search.py --all  # list everything
"""

import argparse
import os
import re
import sys
from pathlib import Path


def get_kb_root():
    """Find knowledge/ directory relative to this script."""
    script_dir = Path(__file__).resolve().parent.parent
    kb = script_dir / "knowledge"
    if not kb.exists():
        print(f"ERROR: knowledge/ directory not found at {kb}", file=sys.stderr)
        sys.exit(1)
    return kb


def parse_frontmatter(filepath):
    """Extract YAML frontmatter from a markdown file."""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception:
        return None, ""

    if not content.startswith("---"):
        return {}, content

    end = content.find("---", 3)
    if end == -1:
        return {}, content

    fm_text = content[3:end].strip()
    body = content[end + 3:].strip()

    # Simple YAML parsing (no dependency needed)
    fm = {}
    for line in fm_text.split("\n"):
        line = line.strip()
        if ":" not in line:
            continue
        key, val = line.split(":", 1)
        key = key.strip()
        val = val.strip()
        # Parse list values like [tag1, tag2]
        if val.startswith("[") and val.endswith("]"):
            items = [x.strip().strip("'\"") for x in val[1:-1].split(",")]
            fm[key] = [x for x in items if x]
        else:
            fm[key] = val.strip("'\"")
    return fm, body


def parse_yaml_solution(filepath):
    """Parse a per-question YAML solution file (e.g. knowledge/solved/<comp>/<qid>.yaml).

    Supports both flat and nested layouts (e.g. meta.tags / meta.category_l1).
    Falls back to regex extraction if PyYAML is unavailable or parsing fails.
    Returns (fm_dict, body_text) or (None, "") on read error.
    """
    try:
        content = Path(filepath).read_text(encoding="utf-8")
    except Exception:
        return None, ""

    fm = {"tags": [], "tools": [], "category": "", "verified": None}

    try:
        import yaml  # type: ignore
        data = yaml.safe_load(content)
        if isinstance(data, dict):
            meta = data.get("meta") if isinstance(data.get("meta"), dict) else {}
            ans = data.get("answer") if isinstance(data.get("answer"), dict) else {}
            fm["tags"] = meta.get("tags") or data.get("tags") or []
            fm["tools"] = data.get("tools") or meta.get("tools") or []
            fm["category"] = (
                meta.get("category_l1") or meta.get("category") or data.get("category") or ""
            )
            fm["verified"] = ans.get("verified", data.get("verified"))
            # Coerce singletons to lists
            if isinstance(fm["tags"], str):
                fm["tags"] = [fm["tags"]]
            if isinstance(fm["tools"], str):
                fm["tools"] = [fm["tools"]]
            return fm, content
    except Exception:
        pass

    # Regex fallback (works without PyYAML)
    for m in re.finditer(r'tags:\s*\[([^\]]+)\]', content):
        fm["tags"].extend(
            [t.strip().strip("'\"") for t in m.group(1).split(",") if t.strip()]
        )
    for m in re.finditer(r'tools:\s*\[([^\]]+)\]', content):
        fm["tools"].extend(
            [t.strip().strip("'\"") for t in m.group(1).split(",") if t.strip()]
        )
    cat_m = re.search(r'category(?:_l1)?:\s*["\']?([\w_]+)', content)
    if cat_m:
        fm["category"] = cat_m.group(1)
    return fm, content


def _is_template(path):
    """Skip _TEMPLATE.md, .gitkeep, leading-underscore files."""
    name = path.name
    return name.startswith("_") or name == ".gitkeep"


def iter_solved_entries(kb_root):
    """Yield (path, fm, body) for every solved entry, recursively.

    Supports both .md (with frontmatter) and .yaml (per-question) formats.
    Skips template/placeholder files.
    """
    solved_dir = kb_root / "solved"
    if not solved_dir.exists():
        return
    for f in solved_dir.rglob("*.md"):
        if _is_template(f):
            continue
        fm, body = parse_frontmatter(f)
        if fm is None:
            continue
        yield f, fm, body
    for f in solved_dir.rglob("*.yaml"):
        if _is_template(f):
            continue
        fm, body = parse_yaml_solution(f)
        if fm is None:
            continue
        yield f, fm, body


def search_by_tags(kb_root, tags):
    """Search solved/ (recursively, .md+.yaml) for files matching any tag."""
    results = []
    for f, fm, body in iter_solved_entries(kb_root):
        file_tags = fm.get("tags", [])
        if isinstance(file_tags, str):
            file_tags = [file_tags]
        if any(t.lower() in [ft.lower() for ft in file_tags] for t in tags):
            results.append((f, fm, body[:200]))
    return results


def search_by_tools(kb_root, tools):
    """Search solved/ (recursively, .md+.yaml) for files using given tools."""
    results = []
    for f, fm, body in iter_solved_entries(kb_root):
        file_tools = fm.get("tools", [])
        if isinstance(file_tools, str):
            file_tools = [file_tools]
        if any(t.lower() in [ft.lower() for ft in file_tools] for t in tools):
            results.append((f, fm, body[:200]))
    return results


def search_by_text(kb_root, query):
    """Full-text search across solved/ (md+yaml), skills/, cards/."""
    results = []
    query_lower = query.lower()

    for subdir in ["solved", "skills", "cards"]:
        search_dir = kb_root / subdir
        if not search_dir.exists():
            continue
        patterns = ["*.md", "*.yaml"] if subdir == "solved" else ["*.md"]
        files = []
        for pat in patterns:
            files.extend(search_dir.rglob(pat))
        for f in files:
            if _is_template(f):
                continue
            try:
                content = f.read_text(encoding="utf-8")
            except Exception:
                continue
            if query_lower in content.lower():
                # Find the matching line for context
                for i, line in enumerate(content.split("\n")):
                    if query_lower in line.lower():
                        start = max(0, i - 1)
                        end = min(len(content.split("\n")), i + 3)
                        context = "\n".join(content.split("\n")[start:end])
                        results.append((f, context))
                        break
    return results


def search_by_category(kb_root, category):
    """Search solved/ (recursively, .md+.yaml) for entries in a category."""
    results = []
    for f, fm, body in iter_solved_entries(kb_root):
        if str(fm.get("category", "")).lower() == category.lower():
            results.append((f, fm, body[:200]))
    return results


def list_all(kb_root):
    """List all knowledge base entries (recursively, .md+.yaml)."""
    print("=== Solved Solutions ===")
    entries = sorted(iter_solved_entries(kb_root), key=lambda x: str(x[0]))
    for f, fm, _ in entries:
        rel = f.relative_to(kb_root / "solved")
        tags = ", ".join(str(t) for t in (fm.get("tags") or []))
        cat = fm.get("category") or "?"
        print(f"  {rel}: [{cat}] tags={tags}")
    print(f"  ({len(entries)} entries total)")

    print("\n=== Skills ===")
    skills_dir = kb_root / "skills"
    if skills_dir.exists():
        for d in sorted(skills_dir.iterdir()):
            if d.is_dir() and d.name != ".gitkeep":
                files = list(d.glob("*.md"))
                print(f"  {d.name}/: {len(files)} files")

    print("\n=== Knowledge Cards ===")
    cards_dir = kb_root / "cards"
    if cards_dir.exists():
        cards = list(cards_dir.glob("*.md"))
        print(f"  {len(cards)} cards")


## Keyword extraction for consultant mode
# Common forensics/security terms mapped to search variants
TERM_ALIASES = {
    "内存": ["memory", "memory_forensics", "vol3", "volatility"],
    "memory": ["memory_forensics", "vol3", "volatility", "内存"],
    "磁盘": ["disk", "disk_forensics", "sleuthkit", "autopsy"],
    "disk": ["disk_forensics", "sleuthkit", "autopsy", "磁盘"],
    "网络": ["network", "pcap", "tshark", "wireshark"],
    "network": ["pcap", "tshark", "wireshark", "网络"],
    "流量": ["pcap", "tshark", "network", "capture"],
    "手机": ["mobile", "android", "ios", "aleapp", "ileapp"],
    "mobile": ["android", "ios", "aleapp", "ileapp", "手机"],
    "隐写": ["stego", "steganography", "steghide", "zsteg", "lsb"],
    "stego": ["steganography", "steghide", "zsteg", "lsb", "隐写"],
    "密码": ["crypto", "password", "hash", "john", "hashcat"],
    "crypto": ["cryptography", "rsa", "aes", "cipher", "密码"],
    "注入": ["injection", "sqli", "sqlmap", "command_injection"],
    "injection": ["sqli", "sqlmap", "command_injection", "注入"],
    "进程": ["process", "pslist", "pstree", "malware"],
    "process": ["pslist", "pstree", "malware", "进程"],
    "web": ["http", "php", "xss", "ssrf", "lfi", "rce"],
    "逆向": ["reverse", "ghidra", "radare2", "binary"],
    "reverse": ["ghidra", "radare2", "binary", "逆向"],
    "取证": ["forensics", "evidence", "analysis"],
    "forensics": ["evidence", "analysis", "取证"],
    "注册表": ["registry", "regripper", "ntuser", "sam"],
    "registry": ["regripper", "ntuser", "sam", "注册表"],
    "日志": ["event_log", "evtx", "chainsaw", "hayabusa", "log"],
    "浏览器": ["browser", "chrome", "firefox", "history", "cookie"],
    "微信": ["wechat", "tencent", "mm", "mobile"],
    "聊天": ["chat", "message", "wechat", "qq", "sms"],
    "图片": ["image", "png", "jpg", "jpeg", "stego", "exiftool"],
    "音频": ["audio", "wav", "mp3", "spectrogram"],
    "视频": ["video", "mp4", "avi"],
    "恶意": ["malware", "malicious", "trojan", "backdoor"],
    "木马": ["trojan", "malware", "backdoor", "rat"],
    "勒索": ["ransomware", "encrypt", "ransom"],
    "删除": ["deleted", "recovery", "carving", "foremost", "undelete"],
    "恢复": ["recovery", "carving", "foremost", "testdisk", "photorec"],
    "时间线": ["timeline", "timestamp", "chronology"],
    "哈希": ["hash", "md5", "sha256", "sha1", "integrity"],
    "编码": ["encoding", "base64", "hex", "url_encode", "rot13"],
}

# Known tool names for tool-dimension search
KNOWN_TOOLS = {
    "vol3", "volatility", "volatility3", "strings", "exiftool", "regripper",
    "chainsaw", "hayabusa", "binwalk", "foremost", "sqlite3", "tshark",
    "tcpdump", "nmap", "curl", "sqlmap", "ffuf", "gobuster", "nuclei",
    "nikto", "hydra", "steghide", "zsteg", "john", "hashcat", "ghidra",
    "radare2", "r2", "gdb", "pwntools", "python3", "adb", "aleapp",
    "ileapp", "mvt", "base64", "xxd", "file", "openssl",
}


def extract_search_terms(question):
    """Extract keywords and their aliases from a natural language question."""
    question_lower = question.lower()

    # Extract English words
    en_words = re.findall(r'[a-z][a-z0-9_\-]*', question_lower)
    # Extract Chinese text and scan for known Chinese terms
    cn_text = re.findall(r'[\u4e00-\u9fff]+', question_lower)
    cn_full = "".join(cn_text)

    tags = set()
    tools = set()
    text_terms = set()

    STOPWORDS = {"the", "a", "an", "is", "are", "how", "to", "do", "i",
                 "in", "of", "and", "or", "for", "what", "can", "with",
                 "this", "that", "from", "my", "me", "we", "if"}

    # Process English words
    for word in en_words:
        if word in STOPWORDS or len(word) <= 1:
            continue
        if word in KNOWN_TOOLS:
            tools.add(word)
        if word in TERM_ALIASES:
            for alias in TERM_ALIASES[word]:
                if alias in KNOWN_TOOLS:
                    tools.add(alias)
                else:
                    tags.add(alias)
        text_terms.add(word)

    # Scan Chinese text for known terms (longest match first)
    cn_keys = sorted(
        [k for k in TERM_ALIASES if re.fullmatch(r'[\u4e00-\u9fff]+', k)],
        key=len, reverse=True
    )
    for term in cn_keys:
        if term in cn_full:
            for alias in TERM_ALIASES[term]:
                if alias in KNOWN_TOOLS:
                    tools.add(alias)
                else:
                    tags.add(alias)
                text_terms.add(alias)  # also search alias as text
            text_terms.add(term)

    # Also add individual meaningful Chinese segments as text terms
    for seg in cn_text:
        if len(seg) >= 2:
            text_terms.add(seg)

    return list(tags), list(tools), list(text_terms)


def consultant_search(kb_root, question):
    """Consultant mode: answer a natural language question from the KB."""
    print(f"\n{'='*60}")
    print(f"  Consultant Mode — Searching KB for: {question}")
    print(f"{'='*60}")

    tags, tools, text_terms = extract_search_terms(question)
    print(f"\n  Extracted search terms:")
    if tags:
        print(f"    Tags:  {tags}")
    if tools:
        print(f"    Tools: {tools}")
    print(f"    Text:  {text_terms}")

    # Collect all matches with relevance scores
    scored = {}  # filepath -> (score, frontmatter, context)

    # Search by tags
    if tags:
        for f, fm, preview in search_by_tags(kb_root, tags):
            key = str(f)
            old_score = scored.get(key, (0, None, ""))[0]
            scored[key] = (old_score + 2, fm, preview)

    # Search by tools
    if tools:
        for f, fm, preview in search_by_tools(kb_root, tools):
            key = str(f)
            old_score = scored.get(key, (0, None, ""))[0]
            scored[key] = (old_score + 2, fm, preview)

    # Search by text (each term independently)
    for term in text_terms:
        for f, context in search_by_text(kb_root, term):
            key = str(f)
            old_score, old_fm, old_ctx = scored.get(key, (0, None, ""))
            scored[key] = (old_score + 1, old_fm, context if not old_ctx else old_ctx)

    if not scored:
        print(f"\n  No relevant knowledge found in KB.")
        print(f"  Suggestion: solve a related challenge or ingest a writeup to build KB coverage.")
        return

    # Sort by score descending
    ranked = sorted(scored.items(), key=lambda x: x[1][0], reverse=True)

    print(f"\n  Found {len(ranked)} relevant entries (ranked by relevance):\n")

    for i, (filepath, (score, fm, context)) in enumerate(ranked[:5]):
        name = Path(filepath).name
        print(f"  {'─'*56}")
        print(f"  #{i+1} [{score} pts] {name}")
        if fm:
            print(f"      Tags:     {fm.get('tags', [])}")
            print(f"      Tools:    {fm.get('tools', [])}")
            print(f"      Category: {fm.get('category', '?')}")
            print(f"      Verified: {fm.get('verified', '?')}")

        # For the top result, show full solution steps if available
        if i == 0:
            try:
                full = Path(filepath).read_text(encoding="utf-8")
                # Extract Solution Steps section
                steps_match = re.search(
                    r'## Solution Steps\n(.*?)(?=\n## |\Z)',
                    full, re.DOTALL
                )
                if steps_match:
                    steps = steps_match.group(1).strip()
                    print(f"\n      === Solution Steps (from top match) ===")
                    for line in steps.split("\n")[:20]:
                        print(f"      {line}")
                    if len(steps.split("\n")) > 20:
                        print(f"      ... ({len(steps.split(chr(10)))-20} more lines, read full file)")

                # Extract Key Takeaways
                takeaway_match = re.search(
                    r'## Key Takeaways\n(.*?)(?=\n## |\Z)',
                    full, re.DOTALL
                )
                if takeaway_match:
                    print(f"\n      === Key Takeaways ===")
                    for line in takeaway_match.group(1).strip().split("\n")[:10]:
                        print(f"      {line}")
            except Exception:
                pass

        print()

    print(f"  {'─'*56}")
    print(f"  Full files at: {kb_root}")
    print(f"  Read top match: {ranked[0][0]}")


def main():
    parser = argparse.ArgumentParser(description="Search AutoForensicAI knowledge base")
    parser.add_argument("--tags", nargs="+", help="Search by tags")
    parser.add_argument("--tools", nargs="+", help="Search by tools used")
    parser.add_argument("--text", help="Full-text search")
    parser.add_argument("--category", help="Search by category")
    parser.add_argument("--ask", help="Consultant mode: natural language question")
    parser.add_argument("--all", action="store_true", help="List all entries")
    args = parser.parse_args()

    kb = get_kb_root()

    if args.all:
        list_all(kb)
        return

    if args.tags:
        results = search_by_tags(kb, args.tags)
        if results:
            print(f"Found {len(results)} solutions matching tags {args.tags}:")
            for f, fm, preview in results:
                print(f"\n--- {f.name} ---")
                print(f"  Tags: {fm.get('tags', [])}")
                print(f"  Tools: {fm.get('tools', [])}")
                print(f"  Category: {fm.get('category', '?')}")
                print(f"  Preview: {preview[:100]}...")
        else:
            print(f"No solutions found for tags: {args.tags}")

    if args.tools:
        results = search_by_tools(kb, args.tools)
        if results:
            print(f"Found {len(results)} solutions using tools {args.tools}:")
            for f, fm, preview in results:
                print(f"\n--- {f.name} ---")
                print(f"  Tags: {fm.get('tags', [])}")
                print(f"  Tools: {fm.get('tools', [])}")
        else:
            print(f"No solutions found for tools: {args.tools}")

    if args.text:
        results = search_by_text(kb, args.text)
        if results:
            print(f"Found {len(results)} matches for '{args.text}':")
            for f, context in results:
                print(f"\n--- {f} ---")
                print(f"  {context[:200]}")
        else:
            print(f"No matches for: {args.text}")

    if args.category:
        results = search_by_category(kb, args.category)
        if results:
            print(f"Found {len(results)} solutions in category '{args.category}':")
            for f, fm, preview in results:
                print(f"\n--- {f.name} ---")
                print(f"  Tags: {fm.get('tags', [])}")
        else:
            print(f"No solutions in category: {args.category}")

    if args.ask:
        consultant_search(kb, args.ask)

    if not any([args.tags, args.tools, args.text, args.category, args.all, args.ask]):
        parser.print_help()


if __name__ == "__main__":
    main()
