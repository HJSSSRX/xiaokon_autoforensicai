#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ask_advisor.py — 取证现场 AI 顾问

用法：
    python ask_advisor.py "题目原文"
    python ask_advisor.py -f question.txt
    python ask_advisor.py "题目" --topk 8 --no-llm    # 只返回知识库召回，不调 LLM
    python ask_advisor.py "题目" --provider deepseek  # 默认
    python ask_advisor.py "题目" --provider qwen
    python ask_advisor.py "题目" --provider openai

环境变量：
    DEEPSEEK_API_KEY / DASHSCOPE_API_KEY / OPENAI_API_KEY
    KNOWLEDGE_DIR (默认: ../knowledge/wp_index 相对本脚本)

依赖：
    仅标准库 + requests（pip install requests）
    可选：jieba（中文分词，没装也能跑）
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from collections import Counter
from pathlib import Path
from typing import Iterable

try:
    import requests  # type: ignore
except ImportError:
    print("请先 pip install requests", file=sys.stderr)
    sys.exit(1)

try:
    import jieba  # type: ignore
    _HAS_JIEBA = True
except ImportError:
    _HAS_JIEBA = False


# ----------------------------- 配置 -----------------------------

PROVIDERS = {
    "deepseek": {
        "url": "https://api.deepseek.com/chat/completions",
        "model": "deepseek-chat",
        "env": "DEEPSEEK_API_KEY",
    },
    "qwen": {
        "url": "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
        "model": "qwen-plus",
        "env": "DASHSCOPE_API_KEY",
    },
    "openai": {
        "url": "https://api.openai.com/v1/chat/completions",
        "model": "gpt-4o-mini",
        "env": "OPENAI_API_KEY",
    },
}

SYSTEM_PROMPT = """你是电子取证比赛（FIC / 平航杯 / 盘古石杯 / 美亚杯）的现场顾问。

身份与边界：
- 你不是答题者，而是教练。给方向，不给最终答案。
- 用户在比赛中亲自动手，你只指导路径。
- 用户提供的"现场题目"是2026年新题，你**没看过**；提供的"召回的历年题"是公开WP里的旧题，可作为思路参考但**不一定相同**。

输出格式（严格遵守，否则用户难用）：
1. **题目识别**：归类（检材类型 + 取证方向 + 关键考点），1-2 句
2. **匹配的历年题**：召回的题里哪些最相似，链接给出，**指出差异**（"这题问 X，新题可能问 Y"）
3. **解题路径**：3-5 步，每步说"用什么工具看什么文件的什么字段"
4. **关键命令/SQL/正则**（如适用）：可直接复制
5. **常见坑**：基于历年套路，提醒用户注意（编码/时区/格式/繁简体等）
6. **置信度**：高/中/低 + 一句理由
7. **如果卡住的备选方向**：一两条 plan B

风格：简体中文，紧凑。不要赘述方法论，直接说怎么做。"""


# ----------------------------- 知识库检索 -----------------------------

# 只保留含义足够强的字符（中文、英文、数字、常见取证符号）
_TOK_RE = re.compile(r"[\w\u4e00-\u9fff\-\.]{2,}")
_STOPWORDS = {
    "请", "分析", "检材", "回答", "以下", "问题", "内容", "什么", "多少", "格式",
    "the", "and", "is", "of", "for", "to", "in", "a", "an", "what", "how",
    "请问", "答案", "标准", "格式", "题目", "正确", "陈述", "描述",
}


_CN_RE = re.compile(r"[\u4e00-\u9fff]+")
_EN_RE = re.compile(r"[a-z0-9][\w\-\.]+", re.IGNORECASE)


def _bigrams(s: str) -> list[str]:
    return [s[i : i + 2] for i in range(len(s) - 1)] if len(s) >= 2 else [s]


def tokenize(text: str) -> list[str]:
    """简单分词。jieba 可选；fallback 时中文用 bigram，英文按词。"""
    text = text.lower()
    if _HAS_JIEBA:
        toks = [t.strip() for t in jieba.cut_for_search(text) if t.strip()]
    else:
        toks = []
        # 中文按 bigram
        for cn in _CN_RE.findall(text):
            toks.extend(_bigrams(cn))
        # 英文按词
        toks.extend(_EN_RE.findall(text))
    return [t for t in toks if t not in _STOPWORDS and len(t) >= 2]


def discover_kb(kb_dir: Path) -> list[Path]:
    return sorted(kb_dir.glob("*.md"))


def search_kb(kb_dir: Path, question: str, topk: int = 5) -> list[dict]:
    """关键词召回。返回 [{file, line_no, content, score}]，按 score 降序。"""
    keywords = set(tokenize(question))
    if not keywords:
        return []

    hits: list[dict] = []
    for md in discover_kb(kb_dir):
        try:
            text = md.read_text(encoding="utf-8")
        except Exception:
            continue
        # 提取头部元数据（来源/检材构成/特色）作为文件级上下文
        header = "\n".join(text.splitlines()[:10])
        # 逐行扫描以 "- Q" 开头的题目
        for ln, line in enumerate(text.splitlines(), 1):
            if not re.match(r"^\s*-\s*Q\d+", line):
                continue
            line_tokens = set(tokenize(line))
            score = len(keywords & line_tokens)
            if score == 0:
                continue
            hits.append({
                "file": md.name,
                "header": header,
                "line_no": ln,
                "content": line.strip(),
                "score": score,
            })

    # 同一文件多次命中合并：保留 top 3 行 / 文件
    by_file: dict[str, list[dict]] = {}
    for h in hits:
        by_file.setdefault(h["file"], []).append(h)
    merged = []
    for fn, items in by_file.items():
        items.sort(key=lambda x: -x["score"])
        for it in items[:3]:
            merged.append(it)

    merged.sort(key=lambda x: -x["score"])
    return merged[:topk]


def get_source_url(header: str) -> str:
    m = re.search(r"\*\*来源\*\*[：:]\s*(\S+)", header)
    return m.group(1) if m else ""


# ----------------------------- LLM 调用 -----------------------------

def call_llm(provider: str, system: str, user: str, timeout: int = 60) -> str:
    cfg = PROVIDERS[provider]
    api_key = os.environ.get(cfg["env"])
    if not api_key:
        raise RuntimeError(f"环境变量 {cfg['env']} 未设置")

    payload = {
        "model": cfg["model"],
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
        "temperature": 0.3,
        "stream": False,
    }
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}

    r = requests.post(cfg["url"], headers=headers, data=json.dumps(payload), timeout=timeout)
    r.raise_for_status()
    data = r.json()
    return data["choices"][0]["message"]["content"]


# ----------------------------- 渲染保存 -----------------------------

def save_markdown(question: str, hits: list[dict], answer: str, out_arg: str | None, project_root: Path) -> Path:
    """把回答渲染为 markdown 保存。返回文件绝对路径。"""
    if out_arg:
        out_path = Path(out_arg).expanduser().resolve()
    else:
        out_dir = project_root / "output"
        out_dir.mkdir(exist_ok=True)
        ts = time.strftime("%Y%m%d_%H%M%S")
        # 取题目前 20 字做文件名前缀（去掉特殊字符）
        snippet = re.sub(r"[^\w\u4e00-\u9fff]+", "_", question.strip())[:20]
        out_path = out_dir / f"{ts}_{snippet}.md"

    parts = [
        f"# AI 顾问回答  ·  {time.strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        "## 你的题目",
        "",
        "> " + question.strip().replace("\n", "\n> "),
        "",
        "## 知识库召回",
        "",
    ]
    if hits:
        parts.append("| 分数 | 来源文件 | 题面 |")
        parts.append("|---|---|---|")
        for h in hits:
            content = h["content"].replace("|", "\\|")[:100]
            parts.append(f"| {h['score']} | `{h['file']}` L{h['line_no']} | {content} |")
    else:
        parts.append("_未召回相关历年题。_")
    parts.extend(["", "---", "", "## 顾问指导", "", answer, ""])

    out_path.write_text("\n".join(parts), encoding="utf-8")
    return out_path


def open_in_default_app(path: Path) -> None:
    """用系统默认程序打开文件（Windows: start; macOS: open; Linux: xdg-open）。"""
    try:
        if sys.platform == "win32":
            os.startfile(str(path))  # type: ignore[attr-defined]
        elif sys.platform == "darwin":
            subprocess.Popen(["open", str(path)])
        else:
            subprocess.Popen(["xdg-open", str(path)])
    except Exception as e:
        print(f"[自动打开失败] {e}，请手动打开 {path}", file=sys.stderr)


# ----------------------------- 主流程 -----------------------------

def build_user_prompt(question: str, hits: list[dict]) -> str:
    parts = ["## 现场题目（2026 新题，你没看过）", "", question.strip(), ""]
    if hits:
        parts.append("## 召回的历年题（仅供参考，不是同一题）")
        parts.append("")
        seen_files = set()
        for h in hits:
            if h["file"] not in seen_files:
                src = get_source_url(h["header"])
                parts.append(f"### 来自 {h['file']}（原文：{src}）")
                seen_files.add(h["file"])
            parts.append(f"- {h['content']}  *(L{h['line_no']}, score={h['score']})*")
        parts.append("")
        parts.append("## 任务")
        parts.append("基于以上召回的历年题套路，按 system prompt 要求的 7 段格式回答现场题。")
    else:
        parts.append("## 任务")
        parts.append("知识库未召回相关历年题。请基于电子取证通用方法论指导用户。")
    return "\n".join(parts)


def main() -> int:
    ap = argparse.ArgumentParser(description="取证现场 AI 顾问")
    ap.add_argument("question", nargs="?", help="题目原文")
    ap.add_argument("-f", "--file", help="从文件读题目")
    ap.add_argument("--topk", type=int, default=5, help="知识库召回 top-K")
    ap.add_argument("--provider", choices=list(PROVIDERS.keys()), default="deepseek")
    ap.add_argument("--no-llm", action="store_true", help="只返回知识库召回，不调 LLM")
    ap.add_argument("--kb", default=None, help="知识库目录（默认 ../knowledge/wp_index）")
    ap.add_argument("--no-save", action="store_true", help="不保存为 markdown 文件")
    ap.add_argument("--no-open", action="store_true", help="保存但不自动打开")
    ap.add_argument("--out", default=None, help="自定义输出文件路径")
    args = ap.parse_args()

    if args.file:
        question = Path(args.file).read_text(encoding="utf-8")
    elif args.question:
        question = args.question
    else:
        print("用法: ask_advisor.py '题目原文' 或 -f question.txt", file=sys.stderr)
        return 2

    kb_dir = Path(args.kb) if args.kb else Path(__file__).resolve().parent.parent / "knowledge" / "wp_index"
    if not kb_dir.exists():
        print(f"知识库目录不存在: {kb_dir}", file=sys.stderr)
        return 2

    hits = search_kb(kb_dir, question, topk=args.topk)

    print("=" * 60)
    print(f"知识库目录: {kb_dir}")
    print(f"召回 {len(hits)} 条历年题：")
    for h in hits:
        print(f"  [{h['score']}] {h['file']}: {h['content'][:80]}")
    print("=" * 60)

    if args.no_llm:
        return 0

    user_prompt = build_user_prompt(question, hits)
    try:
        answer = call_llm(args.provider, SYSTEM_PROMPT, user_prompt)
    except Exception as e:
        print(f"LLM 调用失败: {e}", file=sys.stderr)
        print("\n如需离线使用，加 --no-llm；或把下面 prompt 复制到任意 LLM 网页：\n", file=sys.stderr)
        print("--- SYSTEM ---\n" + SYSTEM_PROMPT)
        print("\n--- USER ---\n" + user_prompt)
        return 1

    print(answer)

    # 渲染保存
    if not args.no_save:
        out_path = save_markdown(question, hits, answer, args.out, kb_dir.parent.parent)
        print(f"\n[已保存] {out_path}", file=sys.stderr)
        if not args.no_open:
            open_in_default_app(out_path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
