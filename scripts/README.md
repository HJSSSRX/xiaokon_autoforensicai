# scripts/

按需添加的解析脚本。**不预先造脚本**——每个脚本都应该来自一个真实出现过的题目。

## 规范

每个脚本遵守：
1. **幂等**：重复跑结果一致。
2. **纯 CLI**：用 `argparse` 接参，不写死路径。
3. **输出规整**：默认 JSON 到 stdout，便于 Cascade 读取；加 `--csv` 或 `--pretty` 可切换人类可读格式。
4. **单一职责**：一个脚本只干一件事。不搞"瑞士军刀"。
5. **顶部写清**：这个脚本是为哪个案子、哪道题写的，日期，作者。

## 模板

```python
#!/usr/bin/env python3
"""
Purpose: one-line description.
Origin : case <name>, question <n>, YYYY-MM-DD.
"""
import argparse, json, sys

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("input")
    ap.add_argument("--pretty", action="store_true")
    args = ap.parse_args()

    result = {...}  # do work

    if args.pretty:
        for k, v in result.items():
            print(f"{k}: {v}")
    else:
        json.dump(result, sys.stdout, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    main()
```
