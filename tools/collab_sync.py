#!/usr/bin/env python3
"""
Collaboration Sync — share findings across machines via Git or LAN.

Modes:
  1. Git mode (internet):  push/pull shared/ to a GitHub case repo
  2. LAN mode (air-gapped): simple HTTP server for local network sync

Usage:
  # ── Git mode ──
  python collab_sync.py git-init <case_dir> --repo <github_url>
  python collab_sync.py git-push <case_dir> --message "traffic: found MAC"
  python collab_sync.py git-pull <case_dir>

  # ── LAN mode (server) ──
  python collab_sync.py lan-serve <case_dir> --port 9999

  # ── LAN mode (client) ──
  python collab_sync.py lan-pull <case_dir> --server 192.168.1.100:9999
  python collab_sync.py lan-push <case_dir> --server 192.168.1.100:9999

  # ── Common ──
  python collab_sync.py post <case_dir> --from mobile --summary "Found trojan MD5" --detail "MD5=ABC..." --related server,traffic
  python collab_sync.py status <case_dir>
  python collab_sync.py answers <case_dir>
"""
import argparse
import datetime
import http.server
import json
import os
import shutil
import subprocess
import sys
import threading
import urllib.request
from pathlib import Path

try:
    import yaml
except ImportError:
    subprocess.run([sys.executable, "-m", "pip", "install", "pyyaml", "-q"], check=False)
    import yaml


# ─── Helpers ───

def shared_dir(case_dir):
    d = Path(case_dir) / "shared"
    d.mkdir(parents=True, exist_ok=True)
    return d


def load_yaml(path):
    if not path.exists():
        return []
    with open(path, encoding="utf-8") as f:
        data = yaml.safe_load(f)
    return data if isinstance(data, list) else []


def save_yaml(path, data):
    with open(path, "w", encoding="utf-8") as f:
        yaml.dump(data, f, allow_unicode=True, default_flow_style=False, sort_keys=False)


def now_str():
    return datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def next_id(findings):
    if not findings:
        return "F001"
    ids = [f.get("id", "") for f in findings if isinstance(f, dict)]
    nums = [int(i[1:]) for i in ids if i and i[0] == "F" and i[1:].isdigit()]
    return f"F{max(nums, default=0) + 1:03d}"


# ─── Post a finding ───

def cmd_post(args):
    sd = shared_dir(args.case_dir)
    findings_path = sd / "findings.yaml"
    findings = load_yaml(findings_path)

    entry = {
        "id": next_id(findings),
        "time": now_str(),
        "from": args.sender,
        "summary": args.summary,
        "detail": args.detail or "",
        "related_to": [r.strip() for r in args.related.split(",")] if args.related else [],
    }
    findings.append(entry)
    save_yaml(findings_path, findings)
    print(f"[+] Posted {entry['id']}: {entry['summary']}")
    return entry


# ─── Status overview ───

def cmd_status(args):
    sd = shared_dir(args.case_dir)

    # Findings
    findings = load_yaml(sd / "findings.yaml")
    print(f"\n=== Findings: {len(findings)} ===")
    for f in findings[-10:]:
        print(f"  {f.get('id','?')} [{f.get('from','?')}] {f.get('summary','')}")

    # Progress
    progress = load_yaml(sd / "progress.yaml")
    if isinstance(progress, list):
        print(f"\n=== Progress ===")
        for p in progress:
            if isinstance(p, dict):
                role = p.get("role", "?")
                status = p.get("status", "?")
                done = p.get("done", 0)
                total = p.get("total", "?")
                print(f"  {role:20s} {done}/{total} ({status})")

    # Answers
    answers_path = sd / "answers.yaml"
    if answers_path.exists():
        answers = load_yaml(answers_path)
        answered = sum(1 for a in answers if isinstance(a, dict) and a.get("answer"))
        print(f"\n=== Answers: {answered}/{len(answers)} ===")


# ─── Answers table ───

def cmd_answers(args):
    sd = shared_dir(args.case_dir)
    answers_path = sd / "answers.yaml"
    answers = load_yaml(answers_path)

    if not answers:
        print("No answers yet.")
        return

    # Print as table
    print(f"\n{'#':<5} {'Category':<12} {'Summary':<30} {'Answer':<25} {'Status':<8} {'Source':<10}")
    print("-" * 90)
    for a in answers:
        if not isinstance(a, dict):
            continue
        status = "✅" if a.get("answer") else "❌"
        print(f"{a.get('num','?'):<5} {a.get('category',''):<12} {a.get('summary','')[:28]:<30} {str(a.get('answer',''))[:23]:<25} {status:<8} {a.get('source',''):<10}")


# ─── Git operations ───

def git_run(case_dir, *git_args):
    result = subprocess.run(
        ["git"] + list(git_args),
        cwd=case_dir,
        capture_output=True, text=True
    )
    if result.returncode != 0 and result.stderr:
        print(f"[git] {result.stderr.strip()}")
    return result


def cmd_git_init(args):
    case_dir = Path(args.case_dir)
    shared = shared_dir(case_dir)

    # Init git in case_dir if not already
    if not (case_dir / ".git").exists():
        git_run(case_dir, "init")
        print("[+] Initialized git repo")

    # Create .gitignore for large evidence files
    gitignore = case_dir / ".gitignore"
    if not gitignore.exists():
        gitignore.write_text(
            "# Evidence files (too large for git)\n"
            "*.E01\n*.e01\n*.vmdk\n*.vhd\n*.dd\n*.raw\n*.zip\n"
            "*.bak\n"
            "mobile/backup/\n"
            "computer/mounted/\n"
            "server/vmdk_root/\n"
            "\n# Keep shared/ tracked\n"
            "!shared/\n",
            encoding="utf-8"
        )

    # Ensure shared files exist
    for fname in ["findings.yaml", "progress.yaml", "answers.yaml"]:
        fpath = shared / fname
        if not fpath.exists():
            save_yaml(fpath, [])

    if args.repo:
        git_run(case_dir, "remote", "add", "origin", args.repo)
        print(f"[+] Remote set to {args.repo}")

    git_run(case_dir, "add", "-A")
    git_run(case_dir, "commit", "-m", "init case workspace")
    print("[+] Case workspace initialized. Now push with: git push -u origin main")


def cmd_git_push(args):
    case_dir = args.case_dir
    git_run(case_dir, "add", "shared/")
    msg = args.message or f"sync {now_str()}"
    git_run(case_dir, "commit", "-m", msg)
    result = git_run(case_dir, "push")
    if result.returncode == 0:
        print(f"[+] Pushed: {msg}")
    else:
        print("[!] Push failed. Try: git pull --rebase first")


def cmd_git_pull(args):
    result = git_run(args.case_dir, "pull", "--rebase")
    if result.returncode == 0:
        print("[+] Pulled latest changes")
    else:
        print("[!] Pull failed — check for conflicts")


# ─── LAN HTTP sync ───

class SyncHandler(http.server.BaseHTTPRequestHandler):
    """Serve and accept shared/ files over HTTP."""

    shared_root = None

    def log_message(self, *a):
        pass  # suppress default logging

    def do_GET(self):
        # GET /findings.yaml → return file content
        fname = self.path.strip("/")
        if fname not in ("findings.yaml", "progress.yaml", "answers.yaml", "status"):
            self.send_error(404)
            return

        if fname == "status":
            # Return all files as JSON
            data = {}
            for fn in ["findings.yaml", "progress.yaml", "answers.yaml"]:
                fpath = self.shared_root / fn
                data[fn] = load_yaml(fpath)
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(data, ensure_ascii=False).encode())
            return

        fpath = self.shared_root / fname
        if not fpath.exists():
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header("Content-Type", "text/yaml")
        self.end_headers()
        self.wfile.write(fpath.read_bytes())

    def do_POST(self):
        # POST /findings.yaml → append to file
        fname = self.path.strip("/")
        if fname not in ("findings.yaml", "progress.yaml", "answers.yaml"):
            self.send_error(400)
            return

        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)

        try:
            incoming = yaml.safe_load(body)
        except Exception:
            self.send_error(400, "Invalid YAML")
            return

        fpath = self.shared_root / fname
        existing = load_yaml(fpath)

        if isinstance(incoming, list):
            # Merge: add items with new IDs
            existing_ids = {e.get("id") for e in existing if isinstance(e, dict)}
            for item in incoming:
                if isinstance(item, dict) and item.get("id") not in existing_ids:
                    existing.append(item)
        elif isinstance(incoming, dict):
            existing.append(incoming)

        save_yaml(fpath, existing)
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(b"OK")
        print(f"  [sync] {fname} updated (+{len(incoming) if isinstance(incoming, list) else 1} items)")


def cmd_lan_serve(args):
    sd = shared_dir(args.case_dir)
    SyncHandler.shared_root = sd

    port = args.port
    server = http.server.HTTPServer(("0.0.0.0", port), SyncHandler)

    # Show local IPs
    import socket
    hostname = socket.gethostname()
    ips = socket.getaddrinfo(hostname, None, socket.AF_INET)
    unique_ips = sorted(set(addr[4][0] for addr in ips))

    print(f"\n╔══════════════════════════════════════════╗")
    print(f"║   LAN Sync Server — port {port}            ║")
    print(f"╚══════════════════════════════════════════╝")
    print(f"  Serving: {sd}")
    print(f"  Other machines connect with:")
    for ip in unique_ips:
        print(f"    python collab_sync.py lan-pull <case_dir> --server {ip}:{port}")
    print(f"\n  Press Ctrl+C to stop.\n")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[+] Server stopped.")


def cmd_lan_pull(args):
    sd = shared_dir(args.case_dir)
    server = args.server.rstrip("/")
    if not server.startswith("http"):
        server = f"http://{server}"

    for fname in ["findings.yaml", "progress.yaml", "answers.yaml"]:
        try:
            url = f"{server}/{fname}"
            data = urllib.request.urlopen(url, timeout=5).read()
            remote_items = yaml.safe_load(data) or []

            local_path = sd / fname
            local_items = load_yaml(local_path)
            local_ids = {e.get("id") for e in local_items if isinstance(e, dict)}

            added = 0
            for item in remote_items:
                if isinstance(item, dict) and item.get("id") not in local_ids:
                    local_items.append(item)
                    added += 1

            if added > 0:
                save_yaml(local_path, local_items)
                print(f"  [+] {fname}: +{added} new items")
            else:
                print(f"  [=] {fname}: up to date")
        except Exception as e:
            print(f"  [!] {fname}: {e}")


def cmd_lan_push(args):
    sd = shared_dir(args.case_dir)
    server = args.server.rstrip("/")
    if not server.startswith("http"):
        server = f"http://{server}"

    for fname in ["findings.yaml", "progress.yaml", "answers.yaml"]:
        fpath = sd / fname
        if not fpath.exists():
            continue
        try:
            data = fpath.read_bytes()
            req = urllib.request.Request(
                f"{server}/{fname}",
                data=data,
                headers={"Content-Type": "text/yaml"},
                method="POST"
            )
            urllib.request.urlopen(req, timeout=5)
            print(f"  [+] {fname}: pushed")
        except Exception as e:
            print(f"  [!] {fname}: {e}")


# ─── Main ───

def main():
    parser = argparse.ArgumentParser(description="AutoForensicAI Collaboration Sync")
    sub = parser.add_subparsers(dest="command")

    # post
    p = sub.add_parser("post", help="Post a finding")
    p.add_argument("case_dir")
    p.add_argument("--from", dest="sender", required=True, help="Role name")
    p.add_argument("--summary", required=True)
    p.add_argument("--detail", default="")
    p.add_argument("--related", default="", help="Comma-separated role names")

    # status
    p = sub.add_parser("status", help="Show collaboration status")
    p.add_argument("case_dir")

    # answers
    p = sub.add_parser("answers", help="Show answers table")
    p.add_argument("case_dir")

    # git-init
    p = sub.add_parser("git-init", help="Initialize case git repo")
    p.add_argument("case_dir")
    p.add_argument("--repo", help="Remote GitHub URL")

    # git-push
    p = sub.add_parser("git-push", help="Push shared/ to remote")
    p.add_argument("case_dir")
    p.add_argument("--message", "-m", default="")

    # git-pull
    p = sub.add_parser("git-pull", help="Pull shared/ from remote")
    p.add_argument("case_dir")

    # lan-serve
    p = sub.add_parser("lan-serve", help="Start LAN sync server")
    p.add_argument("case_dir")
    p.add_argument("--port", type=int, default=9999)

    # lan-pull
    p = sub.add_parser("lan-pull", help="Pull from LAN server")
    p.add_argument("case_dir")
    p.add_argument("--server", required=True, help="host:port")

    # lan-push
    p = sub.add_parser("lan-push", help="Push to LAN server")
    p.add_argument("case_dir")
    p.add_argument("--server", required=True, help="host:port")

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        return

    commands = {
        "post": cmd_post,
        "status": cmd_status,
        "answers": cmd_answers,
        "git-init": cmd_git_init,
        "git-push": cmd_git_push,
        "git-pull": cmd_git_pull,
        "lan-serve": cmd_lan_serve,
        "lan-pull": cmd_lan_pull,
        "lan-push": cmd_lan_push,
    }
    commands[args.command](args)


if __name__ == "__main__":
    main()
