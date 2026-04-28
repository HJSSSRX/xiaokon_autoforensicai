#!/usr/bin/env bash
# 一次性写好三窗口共享文件
SHARED="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared"
mkdir -p "$SHARED/inbox" "$SHARED/answers"

cat > "$SHARED/TASKS.md" <<'TASKS_EOF'
# FIC2026 题目分工表

> 三窗口 SOLO 协作。开赛后由 SERVER 窗口 triage 后填表。

## 窗口分工原则

| 窗口 | 板块 |
|-----|------|
| SERVER（主） | 服务器/Linux/ESXi/Docker/数据库/网络/pcap/路由/防火墙/Web 后台 |
| PC | Windows/Mac PC 镜像/浏览器/注册表/EVTX/MFT/邮件 |
| PHONE | Android/iOS 手机/微信QQ/相册/通讯录/APP 数据 |

## 题目分配（开赛后填）

| 题号 | 简述 | 检材 | 板块 | 分给 | 状态 | 答案位置 |
|-----|------|------|------|------|------|---------|
| - | 待开赛后 SERVER triage | - | - | - | - | - |

## 状态码
- pending 待做
- WIP 进行中
- DONE 已完成
- SKIP 跳过/未解
- WAIT 等其他窗口前置
TASKS_EOF

cat > "$SHARED/inbox/server.md" <<'SRV_EOF'
# SERVER 窗口 inbox

## 启动指令（开赛即执行）
1. 跑 scripts/fic_scan_evidence.sh /mnt/e/fffff-TEMP/2026FIC/2026FIC_20260425112747Q
2. 把题目文件（excel/pdf）转 markdown，放 cases/2026FIC电子取证/questions.md
3. 给所有题目标板块 [SERVER/PC/PHONE]，写到 shared/TASKS.md
4. 给 PC 和 PHONE 的 inbox 各写"分给你的题号清单"
5. 自己开始做 SERVER 板块第一题

## 服务器板块题型预备
- ESXi datastore 挂载（vmfs-fuse + esxcfg-volume）
- Docker 容器分析（/var/lib/docker/overlay2）
- MongoDB/MySQL/Redis 查询
- Java Spring Boot 反编译（jadx /usr/local/bin/jadx）
- pcap 流量分析（tshark/zeek）
- OpenWrt 软路由（binwalk -e + squashfs）
- ssh 爆破（hydra + dicts/）
SRV_EOF

cat > "$SHARED/inbox/pc.md" <<'PC_EOF'
# PC 窗口 inbox

## 启动指令
- 读完所有强制文档后回复"PC 已就绪"
- 等 SERVER 窗口给你分题
- 收到分题后立即开始做

## PC 板块题型预备
- Windows 镜像挂载（ewfmount + losetup + ntfs-3g）
- BitLocker 解密（dislocker 或火眼）
- MFT/Prefetch（MFTECmd/PECmd, Windows 侧）
- EVTX 日志（EvtxECmd）
- 注册表（RECmd）
- 浏览器历史（sqlite3 ~/AppData/.../History）
- 邮件（Foxmail/MailMaster sqlite3）
- 微信 PC 端（wxid/UIN 提取）
PC_EOF

cat > "$SHARED/inbox/phone.md" <<'PH_EOF'
# PHONE 窗口 inbox

## 启动指令
- 读完所有强制文档后回复"PHONE 已就绪"
- 等 SERVER 窗口给你分题
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

cat > "$SHARED/facts.md" <<'FACTS_EOF'
# 共享发现 (Facts)

> 任何窗口发现 IOC（账号/密码/IP/域名/路径/哈希）就追加这里。
> 格式：## YYYY-MM-DD HH:MM [窗口] 主题
> 内容：来源路径 + 值 + 可能用途

---
FACTS_EOF

echo "===== 共享文件就绪 ====="
ls -la "$SHARED/"
echo ""
ls -la "$SHARED/inbox/"
