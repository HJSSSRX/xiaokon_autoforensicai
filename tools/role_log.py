"""
Role Log — 远程角色专用极简日志库 (A 方案: 主被动反转)

设计目标:
  把远程角色面对的协作 API 从 4 个 (findings/progress/blocker/questions)
  压缩到 1 个 (log_answer / log_finding / log_blocker / log_question / log_progress
  全部走 POST /log)。

  远程角色不再手写 PowerShell + ConvertTo-Json (避开中文 UTF-8 陷阱)。
  Hub 不可达时静默失败,不阻断角色解题流程。
  
配置 (远程角色启动时一次性):
  环境变量:
    HUB_URL  = "http://主机IP:8765"  或  cloudflared 公网 URL
    ROLE     = "computer_analyst" / "mobile_analyst" / "server_analyst" / "binary_analyst"

用法 (角色 IDE chat 里 AI 一行就调好):
  >>> import sys; sys.path.insert(0, r"e:\\项目\\自动化取证\\tools")
  >>> import os; os.environ["HUB_URL"] = "http://192.168.1.10:8765"
  >>> os.environ["ROLE"] = "computer_analyst"
  >>> from role_log import log_answer, log_finding, log_blocker
  >>>
  >>> log_answer("Q1", "Windows 10 22H2",
  ...     analysis="读 SOFTWARE\\\\Microsoft\\\\Windows NT\\\\CurrentVersion 的 ProductName",
  ...     evidence_path=["NTFS://Windows/System32/config/SOFTWARE"],
  ...     confidence="high")
  >>>
  >>> log_finding("Chrome 历史里见到 ngrok 域名 xxx.ngrok-free.dev",
  ...     related_to=["server_analyst"])
  >>>
  >>> log_blocker("vc 容器密码暴破 6h 无果",
  ...     needs="希望 mobile 角色检查备忘录有无 16字符密码候选")
"""
import json
import os
import sys
import urllib.request
import urllib.error

DEFAULT_HUB = "http://127.0.0.1:8765"

# ─── 内部 ───

def _hub_url():
    return os.environ.get("HUB_URL", DEFAULT_HUB).rstrip("/")


def _role():
    r = os.environ.get("ROLE", "").strip()
    if not r:
        # 容错: 从命令行第一个参数 / sys.argv 推断
        for a in sys.argv:
            if a.endswith("_analyst"):
                return a
        raise RuntimeError(
            "ROLE 环境变量未设置。请先 os.environ['ROLE']='computer_analyst' "
            "(或 mobile_analyst / server_analyst / binary_analyst)"
        )
    return r


def _post(payload):
    """POST /log 到 Hub。失败静默,不阻断。返回 (ok, response_or_error)."""
    payload["from"] = payload.get("from") or _role()
    data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(
        f"{_hub_url()}/log",
        data=data,
        headers={"Content-Type": "application/json; charset=utf-8"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = resp.read().decode("utf-8", errors="replace")
            try:
                return True, json.loads(body)
            except Exception:
                return True, body
    except urllib.error.HTTPError as e:
        msg = e.read().decode("utf-8", errors="replace")
        print(f"[role_log] Hub HTTP {e.code}: {msg}", file=sys.stderr)
        return False, msg
    except Exception as e:
        print(f"[role_log] Hub unreachable ({e}); continuing locally.", file=sys.stderr)
        return False, str(e)


# ─── 公开 API ───

def log_answer(qid, answer, *, analysis="", evidence_path=None,
               confidence="medium", question="", evidence="",
               category=""):
    """
    解出一题,叫一次。

    参数:
      qid           — 题号 (如 "Q1" / "C03")
      answer        — 答案值 (精确字符串)
      analysis      — 详细解析 (人类可复现的步骤,推荐 50+ 字)
      evidence_path — 证据文件路径列表 (推荐使用绝对路径)
      confidence    — high / medium / low
      question      — 题面原文 (可选,Hub 会缓存以前的)
      evidence      — 关联的 finding ID (如 "F-C003")
      category      — 显式指定 answer category (默认根据 ROLE 推断)
    """
    return _post({
        "kind": "answer",
        "qid": qid,
        "answer": str(answer),
        "analysis": analysis,
        "evidence_path": list(evidence_path) if evidence_path else [],
        "confidence": confidence,
        "question": question,
        "evidence": evidence,
        "category": category,
    })


def log_finding(summary, *, detail="", related_to=None, kind="evidence"):
    """
    发现新东西时叫一次。简短 summary + 详细 detail。

    参数:
      summary     — 一行摘要 (50 字以内)
      detail      — 多行详情 (技术细节、命令、输出片段)
      related_to  — 关联的其他角色列表 (如 ["server_analyst","binary_analyst"])
      kind        — evidence / hypothesis / lead / answer
    """
    return _post({
        "kind": "finding",
        "type": kind,
        "summary": summary,
        "detail": detail,
        "related_to": list(related_to) if related_to else [],
    })


def log_blocker(blocker, needs, *, routed_to=""):
    """
    卡死 30 分钟以上时叫救命。小空(主设计师)会负责路由。

    参数:
      blocker    — 卡点描述 (具体是哪一题、卡在哪个动作)
      needs      — 需要的资源/线索/工具
      routed_to  — 建议路由给谁 (留空让主设计师决定)
    """
    return _post({
        "kind": "blocker",
        "blocker": blocker,
        "needs": needs,
        "routed_to": routed_to,
    })


def log_question(to, question, *, context=""):
    """
    问别的角色时叫一次。

    参数:
      to        — 目标角色名 (computer_analyst / ... / main_designer)
      question  — 提问内容
      context   — 你提问的背景(为什么问)
    """
    return _post({
        "kind": "question",
        "to": to,
        "question": question,
        "context": context,
    })


def log_progress(*, status="in_progress", current_task="",
                 completed=None, pending=None, blocker=""):
    """
    可选:推进里程碑时叫一次。不强制——主设计师会主动观察 finding 流。

    参数:
      status        — idle / in_progress / blocked / paused / done
      current_task  — 当前正在做的事
      completed     — 已完成题号列表 (如 ["Q1","Q2","Q5"])
      pending       — 还没做题号列表
      blocker       — 当前卡点单行描述
    """
    return _post({
        "kind": "progress",
        "status": status,
        "current_task": current_task,
        "completed": list(completed) if completed else [],
        "pending": list(pending) if pending else [],
        "blocker": blocker,
    })


# ─── 自检 ───

def selftest():
    """快速自检: ping Hub + 验证 ROLE 环境变量。"""
    print(f"HUB_URL = {_hub_url()}")
    try:
        print(f"ROLE    = {_role()}")
    except RuntimeError as e:
        print(f"ROLE    = (未设置) {e}")
    try:
        with urllib.request.urlopen(f"{_hub_url()}/ping", timeout=3) as resp:
            print(f"Hub ping = OK ({resp.read().decode('utf-8')})")
    except Exception as e:
        print(f"Hub ping = FAIL ({e})")


if __name__ == "__main__":
    selftest()
