#!/usr/bin/env bash
SHARED="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared"

cat > "$SHARED/TASKS.md" <<'TASKS_EOF'
# FIC2026 题目分工表（两窗口模式）

> 开赛后由 MAIN 窗口 triage 后填表。

## 窗口分工

| 窗口 | 板块 |
|-----|------|
| MAIN（服务器+PC） | 服务器/Linux/ESXi/Docker/数据库/网络/pcap/路由/Web 后台 + Windows/Mac PC 镜像/浏览器/注册表/EVTX/MFT/邮件/PC 端微信 |
| PHONE | Android/iOS 手机/微信QQ/相册/通讯录/APP 数据 |

## 题目分配（开赛后填）

| 题号 | 简述 | 检材 | 板块 | 分给 | 状态 | 答案位置 |
|-----|------|------|------|------|------|---------|
| - | 待开赛后 MAIN triage | - | - | - | - | - |

## 状态码
- pending / WIP / DONE / SKIP / WAIT
TASKS_EOF

cat > "$SHARED/inbox/main.md" <<'MAIN_EOF'
# MAIN 窗口 inbox（服务器+PC）

## 启动指令（开赛即执行）
1. 跑 scripts/fic_scan_evidence.sh /mnt/e/fffff-TEMP/2026FIC/2026FIC_20260425112747Q
2. 题目转 markdown，放 cases/2026FIC电子取证/questions.md
3. 给所有题目标 [MAIN/PHONE]，写到 shared/TASKS.md
4. 给 PHONE 的 inbox 写"分给你的题号清单"
5. 自己开始做 MAIN 板块第一题（按速通题优先）

## 板块覆盖
**服务器侧**：ESXi / Docker / MongoDB / MySQL / Redis / Java / pcap / OpenWrt / ssh 爆破
**PC 侧**：Windows 镜像 / BitLocker / MFT/EVTX/Registry / 浏览器 / 邮件 / PC 微信
MAIN_EOF

cat > "$SHARED/inbox/phone.md" <<'PH_EOF'
# PHONE 窗口 inbox

## 启动指令
- 读完所有强制文档后回复"PHONE 已就绪"
- 等 MAIN 窗口给你分题
- 收到分题后立即开始做

## PHONE 板块题型预备
- Android tar 解包：tar -xf phone.tar -C /tmp/phone_extract
- 微信数据库解密（IMEI+UIN MD5 取前7位为密钥，详见 AI_BRAIN/solved_patterns/pattern_02_wechat_db_decrypt.md）
- QQ 数据库（sqlite3）
- 浏览器/APP 数据
- 相册 EXIF/GPS（exiftool -r）
- WiFi 配置（WifiConfigStore.xml）
- 通话记录/短信
- 输入法痕迹（搜狗/讯飞云词库）
PH_EOF

# 删除旧的 server.md 和 pc.md（合并为 main）
rm -f "$SHARED/inbox/server.md" "$SHARED/inbox/pc.md" "$SHARED/inbox/a.md" "$SHARED/inbox/b.md" "$SHARED/inbox/c.md"

echo "===== 两窗口共享文件就绪 ====="
ls -la "$SHARED/inbox/"
