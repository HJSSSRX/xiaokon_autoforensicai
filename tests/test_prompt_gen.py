"""Test: simulate Main generating role prompts for a competition scenario."""
import os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROLES_DIR = os.path.join(PROJECT_ROOT, "prompts", "roles")
COLLAB_PROTOCOL = os.path.join(PROJECT_ROOT, "prompts", "protocols", "collaboration.md")

# Simulated competition: 2 evidence items
evidence = [
    {"type": "disk_image", "file": "computer.E01", "os": "Windows 10", "role": "computer_analyst"},
    {"type": "pcap", "file": "capture.pcap", "size": "50MB", "role": "network_analyst"},
]

case_dir = r"E:\案件\2026-test"

print("=" * 60)
print("  Main Designer — Competition Mode Prompt Generation")
print("=" * 60)

for ev in evidence:
    role_file = os.path.join(ROLES_DIR, f"{ev['role']}.md")
    if not os.path.exists(role_file):
        print(f"\n[ERROR] Role template not found: {role_file}")
        continue
    
    # Read role template
    with open(role_file, "r", encoding="utf-8") as f:
        role_content = f.read()
    
    # Count lines of the template
    lines = len(role_content.split("\n"))
    
    # Generate customized prompt
    prompt = f"""
{'='*60}
ROLE: {ev['role']}
EVIDENCE: {ev['file']} ({ev.get('os', ev.get('size', ''))})
{'='*60}

{role_content.split(chr(10))[0]}  # Role title

## Assignment
- Working directory: {case_dir}\\{ev['role']}\\
- Evidence: {case_dir}\\challenge\\{ev['file']}
- Evidence type: {ev['type']}

## Knowledge Base
BEFORE you start, search for prior solutions:
  python tools/kb_search.py --tags {ev['type'].replace('_', ' ')}
  python tools/kb_search.py --category {ev['type']}

## Collaboration
- Write findings to: {case_dir}\\shared\\findings.yaml
- Check for leads: {case_dir}\\shared\\findings.yaml
- Ask questions: {case_dir}\\shared\\questions.yaml

(Full role template: {lines} lines loaded from {ev['role']}.md)
"""
    print(prompt)

# Verify collaboration protocol exists
if os.path.exists(COLLAB_PROTOCOL):
    with open(COLLAB_PROTOCOL, "r", encoding="utf-8") as f:
        collab_lines = len(f.read().split("\n"))
    print(f"[OK] Collaboration protocol loaded ({collab_lines} lines)")
else:
    print("[ERROR] Collaboration protocol not found!")

print("\n[OK] All role prompts generated successfully")
print(f"[OK] Role templates available: {os.listdir(ROLES_DIR)}")
