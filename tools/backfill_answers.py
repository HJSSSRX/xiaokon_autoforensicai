"""
v3.1 数据回填脚本 — 把已有 finding 翻译成完整 answer (含 analysis + evidence_path)。

主设计师职责：本来这些应该实时翻译，但 v3 时期 schema 不全 + 没人提取，导致积压。
本脚本一次性把当前所有可翻译的 finding 落到 answers，附最朴素的 analysis（finding summary
+ details + 证据路径）。后续主设计师该实时维护 analysis 字段。

USAGE:  python tools/backfill_answers.py
"""
import urllib.request
import json
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

HUB = "http://127.0.0.1:8765"


def get(path):
    return json.loads(urllib.request.urlopen(f"{HUB}{path}").read())


def post(path, body):
    data = json.dumps(body, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(
        f"{HUB}{path}",
        data=data,
        headers={"Content-Type": "application/json; charset=utf-8"},
        method="POST",
    )
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read().decode("utf-8"))


# ─────────────────────────────────────────────────
# Computer forensics — 从 finding F-C002~F-C010 提取
# ─────────────────────────────────────────────────
COMPUTER_ANSWERS = [
    {
        "qid": "Q1",
        "question": "操作系统版本号",
        "answer": "Deepin 23.1",
        "confidence": "high",
        "evidence": "F-C002",
        "analysis": (
            "从 /etc/os-release 文件读取：\n"
            'PRETTY_NAME="Deepin 23.1"\n'
            "VERSION_ID=23.1\n"
            "ID=deepin\n"
            "复现命令: cat /etc/os-release"
        ),
        "evidence_path": [
            "computer_image/etc/os-release",
            "computer_image/etc/lsb-release",
        ],
    },
    {
        "qid": "Q2",
        "question": "钓鱼邮件发送方邮箱",
        "answer": "hf13338261292@outlook.com",
        "confidence": "high",
        "evidence": "F-C003",
        "analysis": (
            "从 lha 用户的邮件客户端（deepin-mail / Foxmail）提取，钓鱼邮件来自 Token 限时免费\n"
            "邀请的发送方地址。\n"
            "复现路径: ~/.config/deepin-mail/local-cache/ 或 ~/Foxmail/"
        ),
        "evidence_path": [
            "computer_image/home/lha/.config/deepin-mail/",
            "computer_image/home/lha/Foxmail/",
        ],
    },
    {
        "qid": "Q3",
        "question": "黄金换现金商家联系方式",
        "answer": "13612817854",
        "confidence": "medium",
        "evidence": "F-C004",
        "analysis": (
            "从 lha 与张总（黄金换现金商家）的聊天记录（Telegram/微信 PC 端缓存）提取。\n"
            "complete number: 13612817854 (张总)\n"
            "复现路径: ~/.config/Telegram*/ 或 微信 wxFile 数据库"
        ),
        "evidence_path": [
            "computer_image/home/lha/.config/Telegram*/tdata/",
            "computer_image/home/lha/Documents/WeChat Files/",
        ],
    },
    {
        "qid": "Q4",
        "question": "推广设计图中 apk 下载链接",
        "answer": "https://dl.sp-live88.com/update/latest.apk",
        "confidence": "medium",
        "evidence": "F-C005, F-M012",
        "analysis": (
            "lha PC 邮件附件中的「推广设计图.png.enc」加密待解。\n"
            "替代来源: mobile 角色 F-M012 已从 HotClub APK 的 assets/config.dat 解密出 update_url\n"
            "= https://dl.sp-live88.com/update/latest.apk，与推广图所宣传的下载链接同源。\n"
            "QQ002 已发给 mobile 求证手机相册截图能否双重确认。"
        ),
        "evidence_path": [
            "computer_image/home/lha/Mail/推广设计图.png.enc",
            "mobile_image/data/data/com.hotclub/files/config.dat",
        ],
    },
    {
        "qid": "Q5",
        "question": "VPN 软件代理端口",
        "answer": "9527",
        "confidence": "high",
        "evidence": "F-C006",
        "analysis": (
            "从 clash-verge 配置文件提取 mixed-port: 9527\n"
            "config.yaml 关键内容:\n"
            "  mixed-port: 9527\n"
            "  allow-lan: true\n"
            "  mode: rule\n"
            "复现命令: cat ~/.config/clash-verge/config.yaml | grep port"
        ),
        "evidence_path": [
            "computer_image/home/lha/.config/clash-verge/config.yaml",
            "computer_image/home/lha/.config/clash-verge/profiles/",
        ],
    },
    {
        "qid": "Q6",
        "question": "AI 软件当前模型类型",
        "answer": "minimax/minimax-m2.5:free",
        "confidence": "high",
        "evidence": "F-C007",
        "analysis": (
            "从浏览器历史/本地存储发现 lha 使用 OpenRouter 网页版调用 AI 模型。\n"
            "当前选中模型: minimax/minimax-m2.5:free (免费版)\n"
            "证据: localStorage 中 selected_model 键值\n"
            "复现路径: 浏览器开发者工具检查 openrouter.ai 站点的 localStorage"
        ),
        "evidence_path": [
            "computer_image/home/lha/.config/google-chrome/Default/Local Storage/leveldb/",
            "computer_image/home/lha/.config/google-chrome/Default/History",
        ],
    },
    {
        "qid": "Q7",
        "question": "AI 软件 apiKey",
        "answer": "不存在（lha 使用网页版无 apiKey）",
        "confidence": "high",
        "evidence": "F-C008",
        "analysis": (
            "全盘 grep 'sk-' / 'api_key' / 'apiKey' / 'OPENAI_API' / 'ANTHROPIC' / 'OPENROUTER'\n"
            "在 PC 镜像中均无命中。lha 通过浏览器登录 OpenRouter 网页版调用 AI，\n"
            "走的是网页 session token，不存本地 apiKey。\n"
            "答案是「不存在」/「N/A」/「无」（按比赛要求格式定）。"
        ),
        "evidence_path": [
            "computer_image/  (全盘 grep, 无命中)",
        ],
    },
    {
        "qid": "Q8",
        "question": "勒索软件解密服务联系方式",
        "answer": "（待 binary 攻破 vc 容器后查 VHD 内 readme/勒索信）",
        "confidence": "low",
        "evidence": "F-C009",
        "analysis": (
            "F-C009 关键链路: lha 04-15 执行 get_token_linux (root) + 反取证 rm -rf。\n"
            "勒索信很可能藏在 vc 容器内（参考 F-C010）。\n"
            "目前 binary 卡在 RC4 暴破 vc，密码 16 字符 ASCII (SHA1=3e627d9...)。\n"
            "等 vc 解密后查 VHD 内根目录的 README / 勒索信 / contact.txt 类文件。"
        ),
        "evidence_path": [
            "computer_image/home/lha/.bash_history  (04-15 执行记录)",
            "computer_image/U盘/vc  (10MB RC4-encrypted VHD, 待解密)",
        ],
    },
    {
        "qid": "Q9",
        "question": "存放黄金的保险柜编号",
        "answer": "（vc 容器内, 待解密 VHD）",
        "confidence": "low",
        "evidence": "F-C010",
        "analysis": (
            "推断「保险柜」= U盘/vc 容器（10MB AES-128 加密 → 修正为 RC4-VHD, 见 F-B004）\n"
            "保险柜编号 = vc 文件名或解密后 VHD 卷标。当前 vc 暴破阻塞中。\n"
            "等 binary 暴破 16 字符密码后，挂载 VHD 即可看到 volume label。"
        ),
        "evidence_path": [
            "computer_image/U盘/vc",
            "computer_image/home/lha/Desktop/SampleVC.exe",
        ],
    },
    # Q10 还在暴破中，confidence=low 入一个占位
    {
        "qid": "Q10",
        "question": "保险柜密码",
        "answer": "（暴破阻塞中, 16字符 ASCII, SHA1=3e627d9046481366eef9c89183f87004968363d9）",
        "confidence": "low",
        "evidence": "F-C011, F-B003, F-B004",
        "analysis": (
            "vc 容器密码为 16 字符可打印 ASCII，SHA1 = 3e627d9046481366eef9c89183f87004968363d9\n"
            "MD5 = afb977ac242ad60cf46124ad72ca5149\n"
            "binary_analyst 已确认 vc 是 RC4 加密的 VHD（F-B004）。\n"
            "已穷尽 ZxcvbnData (30K) + 智能候选 5921 个，全失败。\n"
            "需要 mobile/computer 重 dump 笔记/密码文件 + 走 SecLists/weakpass 大字典。\n"
            "binary 提供的 RC4 暴破脚本: tools/rc4_solution.py (在 questions QQ010 内)。"
        ),
        "evidence_path": [
            "computer_image/U盘/vc",
            "computer_image/home/lha/.config/  (待重新搜索密码文件)",
            "mobile_image/data/data/com.miui.notes/databases/  (待重 dump)",
        ],
    },
]


# ─────────────────────────────────────────────────
# Binary forensics Q3-Q5 — 把 RC4 突破写进 answers
# ─────────────────────────────────────────────────
BINARY_ANSWERS = [
    {
        "qid": "Q3",
        "question": "正确的密码",
        "answer": "（暴破中, 16字符 ASCII, SHA1=3e627d9046481366eef9c89183f87004968363d9）",
        "confidence": "low",
        "evidence": "F-B003, F-B004, F-B005, F-B006, F-B007",
        "analysis": (
            "三轮分析推进:\n"
            "(1) 初判 AES-128 (F-B003) - 错\n"
            "(2) 二判 AES-128 + MD5 key (F-B003 续) - 错\n"
            "(3) 终判: vc 是 RC4 加密的 VHD (F-B004, 22:49)\n\n"
            "已确认: 密码 16 字符 ASCII, RC4 KSA keylen=16\n"
            "硬约束:\n"
            "- SHA1(P) = 3e627d9046481366eef9c89183f87004968363d9\n"
            "- MD5(P) = afb977ac242ad60cf46124ad72ca5149\n"
            "- RC4 KS 解 vc[0..10] 必须命中已知 FS boot magic (NTFS/FAT32/exFAT)\n\n"
            "Unicorn oracle 已 ready (F-B005)，可精确模拟 SampleVC.exe 密码验证函数。\n"
            "已穷尽: ZxcvbnData (30K) + 8+8 padded (5921) — 全失败。\n"
            "下一步: SecLists / weakpass 大字典 + mobile 重 dump notes + computer 浏览器密码。\n"
            "暴破脚本: 见 questions QQ010 的完整 Python 代码 (双重 SHA1+RC4 验证)。"
        ),
        "evidence_path": [
            "binary/SampleVC.exe  (PE, 密码验证函数 fcn.140002200)",
            "binary/vc  (10MB RC4-encrypted VHD, last 512B 应为 'conectix'+VHD footer)",
        ],
    },
    {
        "qid": "Q4",
        "question": "解密后文件后缀",
        "answer": ".vhd",
        "confidence": "high",
        "evidence": "F-B004",
        "analysis": (
            "vc 文件 = 10MB 整 + 512B footer (典型 VHD Fixed 格式)。\n"
            "VHD Fixed 文件最后 512 字节 footer 起始 8 字节 = 'conectix' magic。\n"
            "binary_analyst 在 22:49 通过结构分析 + RC4 假设确认（F-B004）：\n"
            "解密后挂载方式: VHD Fixed → 直接 file 命令识别 / 7z 挂载 / Windows 双击挂载。\n"
            "答案是 .vhd（按 FIC 比赛常用答题格式确认）。"
        ),
        "evidence_path": [
            "binary/vc",
            "Reference: Microsoft VHD spec (footer 'conectix' magic)",
        ],
    },
    {
        "qid": "Q5",
        "question": "李安弘虚拟币收款总金额",
        "answer": "（待解密 VHD 后查交易记录）",
        "confidence": "low",
        "evidence": "",
        "analysis": (
            "依赖 Q3 暴破成功 + Q4 解密 VHD 后挂载查看内部交易记录文件。\n"
            "可能数据来源:\n"
            "1. VHD 内 wallet.dat / transactions.csv\n"
            "2. mobile F-M006 钱包地址 TN8vQzB3...nU1 + F-M015 USDT 钱包 TXqH7sVn...gA\n"
            "   通过 TRON/USDT 浏览器查链上交易求和\n"
            "3. mobile F-M018 第一笔转账 hash 26226f... 反向查 sender 收入"
        ),
        "evidence_path": [
            "binary/vc  (待解密)",
            "https://tronscan.org/  (链上查询入口)",
        ],
    },
]


# ─────────────────────────────────────────────────
# 提交主程序
# ─────────────────────────────────────────────────
def submit(category, source_role, items):
    print(f"\n=== Backfilling {category} ({len(items)} answers) ===")
    for it in items:
        body = {
            "category": category,
            "qid": it["qid"],
            "question": it["question"],
            "answer": it["answer"],
            "confidence": it["confidence"],
            "source_role": source_role,
            "evidence": it["evidence"],
            "analysis": it["analysis"],
            "evidence_path": it["evidence_path"],
            "verification_status": "unverified",
        }
        try:
            res = post("/answers", body)
            print(f"  ✓ {it['qid']}: {it['answer'][:50]}")
        except Exception as e:
            print(f"  ✗ {it['qid']}: {e}")


if __name__ == "__main__":
    submit("computer_forensics", "computer_analyst", COMPUTER_ANSWERS)
    submit("binary_forensics", "binary_analyst", BINARY_ANSWERS)
    print("\n[Done] 主设计师可在 dashboard 看到完整主表，跑 sync_kb 同步 MASTER_SHEET。")
