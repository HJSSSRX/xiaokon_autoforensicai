#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
ROOT="/tmp/srv_root/@rootfs"
HIST="$ROOT/root/history"
MACCMS="$ROOT/var/www/html/maccms10"

echo "===== LibreOffice 状态 ====="
command -v libreoffice && command -v soffice

echo ""
echo "==========================================" 
echo "maccms 数据库 dump（备份）查找"
echo "=========================================="
SUDO ls $MACCMS/application/data/backup/ 2>/dev/null
SUDO ls $MACCMS/application/data/backup/database/ 2>/dev/null
SUDO find $MACCMS/application/data -type f 2>/dev/null | head -30
echo ""
echo "--- 找所有 .sql .gz .zip 备份 ---"
SUDO find $ROOT/var/www -name '*.sql*' -o -name '*.gz' 2>/dev/null | head -10
SUDO find $ROOT/root -maxdepth 5 -name '*.sql*' -o -name 'dump*' -o -name 'backup*' 2>/dev/null | head -10
SUDO find $ROOT/data -maxdepth 5 -name '*.sql*' 2>/dev/null | head
SUDO find $ROOT/db -name '*.sql*' 2>/dev/null | head

echo ""
echo "==========================================" 
echo "maccms 备份目录详细"
echo "=========================================="
SUDO ls -la $MACCMS/runtime/ 2>/dev/null | head -10
SUDO ls -la $MACCMS/application/data/ 2>/dev/null
echo "--- backup 子目录 ---"
SUDO find $MACCMS/application/data/backup -type f 2>/dev/null | head -30
echo ""
echo "--- /root/history 快照里 maccms backup ---"
SUDO ls $HIST/var/www/html/maccms10/application/data/backup/ 2>/dev/null
SUDO find $HIST/var/www/html/maccms10/application/data/backup -type f 2>/dev/null | head -30

echo ""
echo "==========================================" 
echo "S09: 模板目录"
echo "=========================================="
SUDO ls $MACCMS/template/ 2>/dev/null
echo ""
echo "--- 001tep 模板目录（site config 中 template_dir） ---"
SUDO ls $MACCMS/template/001tep/ 2>/dev/null | head -20
echo ""
echo "--- YMYS002 (主目录看到的) ---"
SUDO ls $MACCMS/template/YMYS002/ 2>/dev/null | head -20
echo ""
echo "--- 站点设置页面用啥模板 (后台模板) ---"
SUDO find $MACCMS/application/admin/view -name 'system*' -o -name 'site*' 2>/dev/null | head -10
SUDO find $MACCMS/application/admin/view -type f -name '*.html' 2>/dev/null | head -20

echo ""
echo "==========================================" 
echo "S14/S15: 注册用户最多日期 + 马慧美登录 IP（看 mac_user_log/access.log）"
echo "=========================================="
SUDO ls $MACCMS/runtime/log/ 2>/dev/null
echo ""
SUDO grep -i '马慧美\|mahuimei\|user.php/admin' $ROOT/var/log/nginx/access.log 2>/dev/null | head -5

echo ""
echo "==========================================" 
echo "I03: ngrok agent 历史（再找）"
echo "=========================================="
SUDO find $ROOT -path '*/log/ngrok*' 2>/dev/null
SUDO find $ROOT/root -name '*.log' 2>/dev/null | head
SUDO find $ROOT/root/history -name '*.log' 2>/dev/null | head
SUDO grep -iro 'ngrok-free\|trycloudflare\|ngrok.io\|ngrok.app\|ngrok.dev' $ROOT/var/log/ 2>/dev/null | head -5
SUDO grep -iro 'ngrok-free\|ngrok.io\|ngrok.app\|ngrok.dev' $ROOT/root/ 2>/dev/null | head -5
echo ""
echo "--- 看 mac 用户 history 完整 (重点 ngrok 命令上下文) ---"
SUDO cat $ROOT/root/.bash_history 2>/dev/null | grep -B2 -A2 ngrok
SUDO cat $HIST/root/.bash_history 2>/dev/null | grep -B2 -A2 ngrok

echo ""
echo "==========================================" 
echo "S13: TiDB 4000 端口（重新找）"
echo "=========================================="
echo "--- mac_history 找 tidb 启动命令 ---"
SUDO cat $ROOT/root/.bash_history 2>/dev/null | grep -i 'tidb\|tiup'
SUDO cat $HIST/root/.bash_history 2>/dev/null | grep -i 'tidb\|tiup'
echo ""
echo "--- LXC mytidb 内 - 完整搜索（递归）---"
SUDO find $HIST/db/tidb $ROOT/var/lib/lxc/mytidb -type f 2>/dev/null | head -30
SUDO ls $HIST/db/ 2>/dev/null
echo ""
echo "--- 也许在 docker 容器 u24 里跑 ---"
SUDO ls $ROOT/data/overlay2 | head
# 找 tidb-server 二进制
SUDO find $ROOT/data/overlay2 -name 'tidb*' 2>/dev/null | head -5
SUDO find $ROOT/data/overlay2 -name '*.tar.gz' 2>/dev/null | head -5
