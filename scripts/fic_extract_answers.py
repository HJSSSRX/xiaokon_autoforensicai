#!/usr/bin/env python3
import os
import re
import glob

ans_dir = "/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared/answers"

print("=== FIC2026 Answers Summary ===\n")

for md_file in sorted(glob.glob(os.path.join(ans_dir, "*.md"))):
    basename = os.path.basename(md_file)
    with open(md_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extract question number and title
    title_match = re.search(r'^##\s+(\w+)\s*[-—]\s*(.+)$', content, re.MULTILINE)
    if title_match:
        q_num = title_match.group(1)
        q_title = title_match.group(2)
    else:
        q_num = basename.replace('.md', '')
        q_title = 'Unknown'
    
    # Extract answer
    answer_match = re.search(r'\*\*答案\*\*[:：]\s*`?([^`\n]+)`?', content)
    if answer_match:
        answer = answer_match.group(1).strip()
    else:
        answer = 'Not found'
    
    # Extract confidence
    conf_match = re.search(r'\*\*置信度\*\*[:：]\s*(\w+)', content)
    confidence = conf_match.group(1) if conf_match else 'Unknown'
    
    print(f"{q_num}: {q_title}")
    print(f"  Answer: {answer}")
    print(f"  Confidence: {confidence}")
    print()
