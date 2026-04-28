#!/usr/bin/env python3
"""
自动化运行助手
帮助减少手动点击run按钮的需要
"""
import subprocess
import time
import os
from datetime import datetime

def run_command_with_notification(command, notification_message):
    """运行命令并在完成后播放提示音"""
    print(f"🚀 执行命令: {command}")
    print(f"⏰ 开始时间: {datetime.now().strftime('%H:%M:%S')}")
    
    try:
        # 执行命令
        result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=300)
        
        print(f"✅ 命令完成")
        print(f"⏰ 结束时间: {datetime.now().strftime('%H:%M:%S')}")
        
        # 播放提示音
        try:
            import winsound
            winsound.MessageBeep(winsound.MB_ICONEXCLAMATION)
            time.sleep(0.3)
            winsound.MessageBeep(winsound.MB_ICONEXCLAMATION)
        except:
            pass
        
        # 记录日志
        log_message = f"{notification_message} - 命令: {command}"
        with open(r"E:\项目\自动化取证\worklog\auto_run.log", "a", encoding="utf-8") as f:
            f.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {log_message}\n")
        
        return result.stdout, result.stderr, result.returncode
        
    except subprocess.TimeoutExpired:
        print("⏰ 命令超时（5分钟）")
        return None, "Timeout", 1
    except Exception as e:
        print(f"❌ 命令执行失败: {e}")
        return None, str(e), 1

def batch_commands(commands, messages):
    """批量执行命令"""
    for i, (cmd, msg) in enumerate(zip(commands, messages)):
        print(f"\n📋 执行第 {i+1}/{len(commands)} 个命令")
        stdout, stderr, code = run_command_with_notification(cmd, msg)
        
        if code != 0:
            print(f"❌ 命令失败: {stderr}")
            break
        
        # 命令间暂停
        if i < len(commands) - 1:
            print("⏳ 等待2秒...")
            time.sleep(2)

if __name__ == "__main__":
    # 示例使用
    commands = [
        "wsl -e bash -c 'ls -la /tmp/'",
        "wsl -e bash -c 'echo \"测试命令\"'",
        "wsl -e bash -c 'date'"
    ]
    
    messages = [
        "列出临时目录",
        "测试命令执行", 
        "获取当前时间"
    ]
    
    batch_commands(commands, messages)
