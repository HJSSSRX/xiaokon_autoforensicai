#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
ROOT="/tmp/srv_root/@rootfs"
HIST="/tmp/srv_root/@rootfs/root/history"

echo "==========================================" 
echo "btrfs 快照 /root/history 探查（重要）"
echo "=========================================="
SUDO ls -la $HIST/ 2>/dev/null
echo ""
echo "--- 快照里的 /db ---"
SUDO ls -la $HIST/db/ 2>/dev/null
SUDO ls -la $HIST/db/tidb/ 2>/dev/null | head -20
echo ""
echo "--- 快照里 mytidb 容器内容 ---"
SUDO ls $HIST/db/tidb/etc/ 2>/dev/null | head -10
SUDO cat $HIST/db/tidb/etc/os-release 2>/dev/null
echo ""
echo "--- 快照里 mysql data ---"
SUDO ls $HIST/db/tidb/var/lib/mysql/ 2>/dev/null
SUDO ls $HIST/db/tidb/var/lib/mysql/mac2/ 2>/dev/null | head -20
echo ""
echo "--- 快照里 root.bash_history ---"
SUDO cat $HIST/root/.bash_history 2>/dev/null | tail -30

echo ""
echo "==========================================" 
echo "PC _dde_data 分区挂载"
echo "=========================================="
PC_IMG="/tmp/fic2026/pc/ewf/ewf1"
PC_LOOP=$(SUDO losetup -j "$PC_IMG" | head -1 | cut -d: -f1)
echo "PC loop: $PC_LOOP"
SUDO mkdir -p /tmp/pc_data
# _dde_data 是 p5（ext4 16GB）
SUDO mount -o ro ${PC_LOOP}p5 /tmp/pc_data 2>&1
echo "挂载结果："
SUDO ls -la /tmp/pc_data/ | head -20
echo ""
echo "--- _dde_data 内容（查找用户家目录） ---"
SUDO find /tmp/pc_data -maxdepth 3 -type d 2>/dev/null | head -30

echo ""
echo "==========================================" 
echo "查找 PC 用户（找李安弘）"
echo "=========================================="
SUDO cat /tmp/pc_root/etc/passwd | awk -F: '($3>=1000)&&($1!="nobody")' 2>/dev/null
echo ""
echo "--- /home 如果在另一个分区 ---"
SUDO find /tmp/pc_data -maxdepth 4 -name '.bash_history' 2>/dev/null | head
SUDO find /tmp/pc_data -maxdepth 4 -name '.bashrc' 2>/dev/null | head

echo ""
echo "==========================================" 
echo "I03: ngrok 实际访问的域名（agent 日志）"
echo "=========================================="
echo "--- ngrok agent log ---"
SUDO find $ROOT/root -name '*ngrok*' -type f 2>/dev/null
SUDO ls $ROOT/root/.ngrok/ $ROOT/root/.ngrok2/ 2>/dev/null
SUDO ls $ROOT/root/.config/ngrok/ 2>/dev/null
echo ""
echo "--- ngrok 默认 log 位置 ---"
SUDO find $ROOT -name 'ngrok.log' 2>/dev/null | head
SUDO find $ROOT/root -name 'agent.log' 2>/dev/null | head
SUDO find $ROOT/root/history -name '*ngrok*' 2>/dev/null | head -10
echo ""
echo "--- nginx access.log 可能记录 ngrok 访问 ---"
SUDO ls $ROOT/var/log/nginx/ 2>/dev/null
SUDO tail -20 $ROOT/var/log/nginx/access.log 2>/dev/null

echo ""
echo "==========================================" 
echo "B03: SampleVC.exe 密码（字符串+反编译）"
echo "=========================================="
EXE="/tmp/fic_extract/SampleVC.exe"
echo "--- 字符串中关键词 ---"
strings -a -n 6 $EXE 2>/dev/null | grep -iE 'pass|密码|key|secret|truecrypt|veracrypt' | head -30
echo ""
echo "--- 字符串中长串 (可能是密码或路径) ---"
strings -a -n 12 $EXE 2>/dev/null | head -40
echo ""
echo "--- 文件类型 ---"
file $EXE
echo ""
echo "--- PE 节区 ---"
SUDO bash -c "command -v rabin2 >/dev/null 2>&1 && rabin2 -S $EXE 2>/dev/null | head -10"
SUDO bash -c "command -v rabin2 >/dev/null 2>&1 && rabin2 -I $EXE 2>/dev/null | head"

echo ""
echo "==========================================" 
echo "S07: 主域名（在 mac_config 表，但容器空，从 /root/history 快照查）"
echo "=========================================="
SUDO ls $HIST/var/www/html/maccms10/ 2>/dev/null | head
SUDO grep -rh 'wap_domain\|main_domain\|site_url\|domain' $HIST/var/www/html/maccms10/application/extra/ 2>/dev/null | head -20
