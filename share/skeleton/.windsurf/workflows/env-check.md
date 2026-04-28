---
description: 会话开头或怀疑环境坏了时跑健康检查
---

当用户说 /env-check 时：

1. 在 PowerShell 跑 `powershell -ExecutionPolicy Bypass -File scripts\env_healthcheck.ps1`
   // turbo
2. 如果 FAIL > 0，读输出决定修复方向：
   - Windows 工具缺 → 跑 `scripts\install_windows_tools.ps1`
   - WSL 工具缺 → WSL 内跑 `bash scripts/install_wsl_tools.sh`
   - 文档缺 → 报告给用户让其确认是不是新机器首次使用
3. 修完重跑 healthcheck 直到全 PASS。
4. 报告结果，不主动跑题目工具。
