"""Quick test: verify shared/findings.yaml is valid and parseable."""
import yaml
import sys

filepath = r"tests\test_challenge\shared\findings.yaml"
with open(filepath, "r", encoding="utf-8") as f:
    data = yaml.safe_load(f)

print(f"Entries: {len(data)}")
for d in data:
    print(f"  {d['id']}: [{d['type']}] {d['summary']}")
    
print("\n[OK] findings.yaml is valid YAML and parseable by any agent")
