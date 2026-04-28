#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
ANS="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared/answers"

cat > "$ANS/C02_main_pc_phishing_email.md" <<'A'
## C02 — 计算机检材中钓鱼邮件的发送用户邮箱

> 分析计算机检材，李安弘曾收到一份免费领取token的邮件的疑似钓鱼邮件，其发送用户邮箱为

**答案**: `hf13338261292@outlook.com`  **置信度**: 高

### 解析

**识别**: 计算机用户 lha (主目录在 _dde_data 分区) 使用 deepin-mail 客户端（IMAP 同步 163 邮箱 lihongan19851024@163.com），邮件存储在 `~/.local/share/deepin/deepin-mail/imap.163.com/lihongan19851024@163.com/imap/<UUID>/mail.eml`。

**提取**:
```bash
# 在所有邮件 .eml 中搜含 "token" 关键词
sudo grep -l -i 'token' /tmp/pc_data/home/lha/.local/share/deepin/deepin-mail/.../imap/*/mail.eml
```

**分析+验证**:

定位邮件 `d46d81a9-6100-4998-8f44-b0ec773b790c/mail.eml`，邮件头：
```
Date: Tue, 14 Apr 2026 14:08:27 +0800
From: "hf13338261292@outlook.com" <hf13338261292@outlook.com>
Subject: =?GB2312?B?VG9rZW4gz97KscPit9HB7A==?=
```

Subject 解码（GB2312 base64）：
```python
import base64
base64.b64decode("VG9rZW4gz97KscPit9HB7A==").decode("gb2312")
# => "Token 限时免费领"
```

完美匹配题面"免费领取 token 的疑似钓鱼邮件"。发件方邮箱：**hf13338261292@outlook.com**（一个常见手机号开头的临时邮箱模式，符合钓鱼邮件特征）。

另：UUID `42e7eeb9...` 是李安弘自己的回复邮件（From: lihongan19851024@163.com，Subject: 回复：Token 限时免费领），不是发送方。

### 不作弊声明
- 数据来源: 检材1 _dde_data 分区 deepin-mail
- 工具: grep, head, base64 (Python)
- 脚本: scripts/fic_save_c05_emails.sh
A

ls -la "$ANS"
echo "Saved C02"

echo ""
echo "==========================================" 
echo "S08/S10/S13/S14/S15/S17 攻坚"
echo "=========================================="
ROOT="/tmp/srv_root/@rootfs"
HIST="$ROOT/root/history"
MACCMS="$ROOT/var/www/html/maccms10"

echo "--- S17: systemd active 服务（数据库）---"
SUDO ls $ROOT/etc/systemd/system/multi-user.target.wants/

echo ""
echo "--- 数据库相关 dpkg 安装记录 ---"
SUDO grep -E 'mysql|mariadb|postgres|redis|mongo|tidb' $ROOT/var/log/dpkg.log 2>/dev/null | grep ' install ' | head -20

echo ""
echo "--- S10: maccms 伪静态规则文件 sm3 (国密 hash) ---"
SUDO ls $MACCMS/static/ $MACCMS/static_new/ 2>/dev/null | head
echo ""
SUDO find $MACCMS -name '*.conf' -o -name 'rewrite*' -o -name '.htaccess' 2>/dev/null | head -10
echo ""
SUDO find $MACCMS -name '*伪静态*' -o -name '*rewrite*' 2>/dev/null | head -10
SUDO find $ROOT -name '*伪静态*.conf' 2>/dev/null | head
echo ""
echo "--- maccms 后台 install 目录 ---"
SUDO ls $MACCMS/application/extra/ 2>/dev/null
echo ""
SUDO cat $MACCMS/application/extra/maccms.php 2>/dev/null | head -100

echo ""
echo "--- S13: TiDB 实际版本（看 docker 容器 u24 内）---"
SUDO ls $ROOT/data/containers/b8a338*/ 2>/dev/null
SUDO cat $ROOT/data/containers/b8a338*/config.v2.json 2>/dev/null | jq '.Config.Image, .Config.Cmd, .Config.Env' 2>/dev/null
echo ""
echo "--- u22 镜像 / overlay2 找 tidb 二进制 ---"
SUDO find $ROOT/data/overlay2 -name 'tidb-server' 2>/dev/null | head -3
SUDO find $ROOT/data -name '*.json' -path '*image/overlay2/imagedb*' 2>/dev/null | head -5
echo ""
echo "--- 4000 端口具体程序 (查 lsof 历史/服务文件) ---"
SUDO grep -r '4000' $ROOT/etc/systemd/system/ 2>/dev/null | head -5
