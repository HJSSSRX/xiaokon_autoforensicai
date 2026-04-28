#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
ROOT="/tmp/srv_root/@rootfs"
PCD="/tmp/pc_data"
PCR="/tmp/pc_root"

echo "==========================================" 
echo "C04: 推广 Pictures OCR (修中文路径)"
echo "=========================================="
mkdir -p /tmp/fic_extract/promo
# 用 find + cp 处理可能的权限问题
SUDO find $PCD/root -type f \( -iname '*.jpeg' -o -iname '*.jpg' -o -iname '*.png' \) 2>/dev/null | head -30
echo ""
SUDO cp -r $PCD/root/Pictures /tmp/fic_extract/promo/Pictures 2>&1
SUDO chown -R hjsssr:hjsssr /tmp/fic_extract/promo/
ls -la /tmp/fic_extract/promo/Pictures/ 2>/dev/null | head -15
echo ""
echo "--- OCR (chi_sim+eng) 找 APK 链接/下载/URL ---"
for img in /tmp/fic_extract/promo/Pictures/*.jpeg /tmp/fic_extract/promo/Pictures/*.png; do
  [ -f "$img" ] || continue
  echo ""
  echo "=== $(basename $img) ==="
  tesseract "$img" - -l chi_sim+eng 2>/dev/null | head -40
done

echo ""
echo "==========================================" 
echo "C06/C07: AI 软件 + apiKey (TRAE / Ollama / etc)"
echo "=========================================="
echo "--- 查 TRAE 配置 ---"
SUDO find $PCD $PCR -iname '*trae*' 2>/dev/null | head -10
SUDO find $PCD/root/.config $PCD/home/lah/.config -iname '*trae*' 2>/dev/null
echo ""
echo "--- ollama / lmstudio / chatbox / cherry studio ---"
SUDO find $PCD/root/.config $PCD/root/.local -maxdepth 4 -iname '*ollama*' -o -iname '*lmstudio*' -o -iname '*chatbox*' -o -iname '*cherry*' -o -iname '*chatgpt*' -o -iname '*deepseek*' -o -iname '*gemini*' 2>/dev/null | head -20
echo ""
echo "--- 安装的应用程序 (.desktop) ---"
SUDO grep -l 'AI\|Trae\|Ollama\|ChatGPT\|Cherry\|deepseek\|GPT' $PCD/root/桌面/*.desktop $PCD/usr/share/applications/*.desktop 2>/dev/null | head
SUDO ls $PCD/opt/ 2>/dev/null
SUDO ls $PCR/opt/ 2>/dev/null
echo ""
echo "--- /usr/share/applications 含 AI 相关 ---"
SUDO grep -l -i 'ai\|trae\|chat\|llm\|model' $PCR/usr/share/applications/*.desktop 2>/dev/null | head
echo ""
echo "--- cef_user_data 可能是 Trae/Cursor (Electron) ---"
SUDO ls $PCD/root/.config/cef_user_data/ 2>/dev/null
SUDO cat $PCD/root/.config/cef_user_data/Local\ State 2>/dev/null | head -200
echo ""
echo "--- grep apiKey/api_key 在 ~/.config 全文 ---"
SUDO grep -ril 'api_key\|apiKey\|sk-\|openai\|anthropic' $PCD/root/.config 2>/dev/null | head -10

echo ""
echo "==========================================" 
echo "C03: 黄金换现金商家联系方式"
echo "=========================================="
echo "--- 邮件里搜 ---"
SUDO grep -ril '黄金\|gold\|金条' $PCD/root/.config/deepin/deepin-mail 2>/dev/null | head -5
SUDO grep -rao '黄金\|金条\|gold' $PCD/root/.config/deepin/deepin-mail 2>/dev/null | head -10
echo ""
echo "--- 桌面/文档搜 黄金 现金 ---"
SUDO find $PCD/root/桌面 $PCD/root/文档 $PCD/root/Documents -type f 2>/dev/null | head -30
SUDO grep -ril '黄金\|现金\|金条\|gold' $PCD/root/桌面 $PCD/root/文档 2>/dev/null | head
echo ""
echo "--- bash_history root ---"
SUDO cat $PCD/root/.bash_history 2>/dev/null | head -50

echo ""
echo "==========================================" 
echo "C08: 勒索软件解密联系"
echo "=========================================="
echo "--- 搜 ransom / decrypt / readme / .txt 在 桌面 ---"
SUDO find $PCD/root -maxdepth 4 -iname '*ransom*' -o -iname '*decrypt*' -o -iname 'README*' -o -iname '*恢复*' -o -iname 'HOW_TO*' 2>/dev/null | head
SUDO find $PCD/root -maxdepth 3 -iname '*.locked' -o -iname '*.encrypted' -o -iname '*.crypt*' 2>/dev/null | head
echo ""
echo "--- 桌面文件 ---"
SUDO ls $PCD/root/桌面/ 2>/dev/null
echo ""
echo "--- root 主目录文件 ---"
SUDO ls -la $PCD/root/ 2>/dev/null | head -30

echo ""
echo "==========================================" 
echo "S09: 站点设置页面前端模板源文件"
echo "=========================================="
MACCMS="$ROOT/var/www/html/maccms10"
echo "--- System.php controller 处理啥 action ---"
SUDO head -100 $MACCMS/application/admin/controller/System.php 2>/dev/null
echo ""
echo "--- view_new/system 下文件 ---"
SUDO ls $MACCMS/application/admin/view_new/system/ 2>/dev/null
echo ""
echo "--- view_new/system/config.html 头 30 行 (站点设置主页) ---"
SUDO head -30 $MACCMS/application/admin/view_new/system/config.html 2>/dev/null

echo ""
echo "==========================================" 
echo "S16: 文件系统未被使用 (推断)"
echo "=========================================="
echo "--- /etc/fstab ---"
SUDO cat $ROOT/etc/fstab 2>/dev/null
echo ""
echo "--- 已加载的 fs 模块 ---"
SUDO ls $ROOT/lib/modules/*/kernel/fs/ 2>/dev/null | head -30
echo ""
echo "--- mkfs 工具列表 ---"
SUDO ls $ROOT/sbin/mkfs* $ROOT/usr/sbin/mkfs* 2>/dev/null

echo ""
echo "==========================================" 
echo "S17: 数据库服务 (查 dpkg 已安装的 db 包)"
echo "=========================================="
echo "--- dpkg list 里 db 相关 ---"
SUDO grep -E 'mysql|maria|postgres|redis|mongo|tidb|sqlite|tikv|memcached' $ROOT/var/lib/dpkg/status 2>/dev/null | grep -E '^Package:' | sort -u
echo ""
echo "--- /etc/systemd/system services ---"
SUDO ls $ROOT/etc/systemd/system/multi-user.target.wants/ 2>/dev/null | grep -iE 'sql|redis|mongo|db|tidb|tikv|pd'
SUDO ls $ROOT/lib/systemd/system/ 2>/dev/null | grep -iE 'sql|redis|mongo|tidb|tikv|pd' | head
echo ""
echo "--- 监听端口 (netstat 替代：从 nginx upstream 看) ---"
SUDO grep -ri 'proxy_pass\|upstream' $ROOT/etc/nginx/ 2>/dev/null | head -10
