---
tags: [computer_forensics, windows, wsl, powershell, browser, mysql, remote_connection, password_cracking]
tools: [火眼, wsl, powershell, chrome, mysql, sshpass]
category: computer_forensics
difficulty: medium
source: 2022_changancup
date: 2026-05-05
verified: true
---
# Title: 2022长安杯 — 计算机取证（检材2 Windows）

## Problem
分析嫌疑技术员的 Windows 个人电脑，提取登录密码、远程连接记录、浏览器密码、WSL 子系统等信息。

## Solution Steps

1. 获取 Windows 账户密码
   → 使用火眼分析工具直接解析

2. 查找远程连接记录
   → 火眼分析结果中排除已知 IP，找到其他远程连接 IP

3. 查找 PowerShell 最后执行命令
   - **注意**: 不是 WSL 的 bash history
   - PowerShell 历史记录位置:
   ```
   %USERPROFILE%\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
   ```

4. 查找下载的涉案网站源代码
   → 仿真后查看"下载"文件夹
   → 通过 GitHub 搜索源码框架名称（ZTuoExchange_framework）确认

5. 查找管理后台密码
   → Chrome 浏览器保存的密码中直接发现

6. 确定使用的 WSL 子系统版本
   - WSL 安装位置: `C:\Users\{username}\AppData\Local\Packages`
   - 方法1: 对比子系统目录大小，实际使用的较大
   - 方法2: 仿真后启动，能直接进入命令行的是在用的
   - 方法3: `wsl -l -v` 查看

7. 查看 MySQL 版本
   ```
   mysql --version
   ```

8. 查找 debian-sys-maint 密码
   ```
   cat /etc/mysql/debian.cnf
   ```

9. 从 SSH 历史中提取另一台服务器密码
   → `sshpass -p 'h123456' ssh root@172.16.80.128`

## Key Takeaways
- PowerShell 历史记录在 `PSReadLine\ConsoleHost_history.txt`，不要与 WSL bash_history 混淆
- Chrome 保存的密码是重要的取证数据来源
- WSL 子系统在 `AppData\Local\Packages` 下，目录大小反映使用程度
- `sshpass` 命令会在 history 中暴露明文密码
- debian-sys-maint 是 Debian/Ubuntu MySQL 的特殊维护账户，密码在 `/etc/mysql/debian.cnf`
