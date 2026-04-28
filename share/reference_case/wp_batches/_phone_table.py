import os, re
ANS = "/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared/answers"
rows = []
for fn in sorted(os.listdir(ANS)):
    if not fn.endswith(".md") or not fn.startswith("M"):
        continue
    text = open(os.path.join(ANS, fn), encoding="utf-8").read()
    m_title = re.search(r"^## (M\d+) — (.+)$", text, re.MULTILINE)
    qid = m_title.group(1) if m_title else fn
    short = m_title.group(2) if m_title else ""
    m_q = re.search(r"\n> (.+)\n", text)
    question = m_q.group(1).strip() if m_q else ""
    m_ans = re.search(r"\*\*答案\*\*`?([^`\n]+)`?", text)
    answer = m_ans.group(1).strip() if m_ans else ""
    m_conf = re.search(r"\*\*置信度\*\*：(\S+)", text)
    conf = m_conf.group(1) if m_conf else ""
    section = text.split("### 解析")[-1].split("### 不作弊声明")[0] if "### 解析" in text else ""
    summary = ""
    for line in section.splitlines():
        line = line.strip()
        if line and not line.startswith("#") and not line.startswith("-") and not line.startswith("|") and not line.startswith("`") and not line.startswith("```"):
            summary = re.sub(r"[`*]", "", line)
            break
    if not summary:
        lines = [l.strip() for l in section.splitlines() if l.strip() and not l.startswith("#") and not l.startswith("-")]
        if lines:
            summary = re.sub(r"[`*]", "", lines[0])[:120]
    rows.append((qid, short, question, answer, conf, summary))

print("| 题号 | 简称 | 题目 | 答案 | 置信度 | 解析摘要 |")
print("|------|------|------|------|--------|----------|")
for qid, short, question, answer, conf, summary in rows:
    q_short = question[:55] + "…" if len(question) > 55 else question
    a_short = answer[:35] + "…" if len(answer) > 35 else answer
    s_short = summary[:90] + "…" if len(summary) > 90 else summary
    print(f"| {qid} | {short} | {q_short} | `{a_short}` | {conf} | {s_short} |")
print(f"\n**共 {len(rows)} 题**")
