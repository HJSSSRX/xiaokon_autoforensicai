#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
任务完成提示音脚本
在完成题目或遇到API限制时播放提示音
"""
import winsound
import time
import sys
from datetime import datetime

def play_notification_sound():
    """播放提示音"""
    try:
        # 播放系统提示音
        winsound.MessageBeep(winsound.MB_ICONEXCLAMATION)
        time.sleep(0.5)
        winsound.MessageBeep(winsound.MB_ICONEXCLAMATION)
        print(f"[提示音] 已播放 - {datetime.now().strftime('%H:%M:%S')}")
    except Exception as e:
        print(f"播放提示音失败: {e}")

def log_completion(message):
    """记录完成状态"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    log_entry = f"[{timestamp}] {message}\n"
    
    with open(r"E:\项目\自动化取证\worklog\task_completion.log", "a", encoding="utf-8") as f:
        f.write(log_entry)
    
    print(f"[记录] 已记录: {message}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        message = " ".join(sys.argv[1:])
        log_completion(message)
        play_notification_sound()
    else:
        print("用法: python notify_when_done.py '完成的消息'")
        print("示例: python notify_when_done.py 'Q55题目已完成'")
