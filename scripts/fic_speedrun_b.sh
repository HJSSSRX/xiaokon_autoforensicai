#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
ROOT="/tmp/srv_root/@rootfs"
PCD="/tmp/pc_data"
PCR="/tmp/pc_root"
ANS="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared/answers"

# 落盘 S09
cat > "$ANS/S09_site_config_template.md" <<'A'
## S09 — 服务器站点设置前端模板源文件

> 服务器上的网站后台中"站点设置"页面前端模板来自于哪个源文件

**答案**: `application/admin/view_new/system/config.html`  **置信度**: 高

### 解析

**识别**: maccms10 后台路由 `/user.php/admin/system/config.html`，对应控制器 `application/admin/controller/System.php` 的 `config()` 方法。该方法不显式指定 view，按 ThinkPHP 默认会自动加载与控制器/方法同名的模板，即 `view_new/system/config.html`（受全局 view 配置）。后台模板路径在 maccms 配置里以 `view_new/` 为目录。

**提取**:
```bash
# 控制器
sudo grep -n 'function config' /tmp/srv_root/@rootfs/var/www/html/maccms10/application/admin/controller/System.php
# 模板存在
sudo ls /tmp/srv_root/@rootfs/var/www/html/maccms10/application/admin/view_new/system/config.html
sudo head -30 /tmp/srv_root/@rootfs/var/www/html/maccms10/application/admin/view_new/system/config.html
```

模板首行：
```
{include file="../../../application/admin/view_new/public/head" /}
```

页面包含 4 个标签页：基础设置(base)/性能(performance)/参数(parameters)/后台(backstage)，与 maccms10 站点设置功能完全对应。

**分析+验证**: 同目录下其它 `config*.html` 是子页面（API/Email/Pay/SMS 等），唯一的"站点设置主页"就是 `config.html`。

### 不作弊声明
- 数据来源: 服务器检材 `/var/www/html/maccms10/application/admin/`
- 工具: ls / head / grep
A
echo "Saved S09"

echo ""
echo "==========================================" 
echo "C04 修正：root 中文路径 /图片"
echo "=========================================="
SUDO ls $PCD/root/图片/ 2>&1 | head
echo ""
mkdir -p /tmp/fic_extract/promo
SUDO cp -r $PCD/root/图片/. /tmp/fic_extract/promo/ 2>&1
SUDO chown -R hjsssr:hjsssr /tmp/fic_extract/promo/
ls -la /tmp/fic_extract/promo/

echo ""
echo "--- OCR 推广图片 ---"
for img in /tmp/fic_extract/promo/*; do
  [ -f "$img" ] || continue
  echo ""
  echo "=== $(basename $img) ==="
  tesseract "$img" - -l chi_sim+eng 2>/dev/null
done > /tmp/fic_extract/ocr_pics.txt 2>&1
grep -E 'apk|http|\.com|\.cn|\.io|\.app|下载|地址|链接|官网|码|网站' /tmp/fic_extract/ocr_pics.txt | head -30
echo ""
echo "--- OCR 完整输出 ---"
cat /tmp/fic_extract/ocr_pics.txt | head -200

echo ""
echo "==========================================" 
echo "C06/C07: AI 软件 (重新找 - 全局)"
echo "=========================================="
echo "--- /opt/ 下应用 ---"
SUDO ls -la $PCR/opt/ 2>/dev/null
echo ""
echo "--- /usr/share/applications 全部 desktop ---"
SUDO ls $PCR/usr/share/applications/ 2>/dev/null | grep -vE '^(deepin|dde|com.deepin|kingsoft|firefox|libreoffice|wps)'
echo ""
echo "--- root/.local/share/applications ---"
SUDO ls $PCD/root/.local/share/applications/ 2>/dev/null
echo ""
echo "--- 桌面 全部 (含隐藏) ---"
SUDO ls -la $PCD/root/桌面/ 2>/dev/null
echo ""
echo "--- root/.config 完整列出 ---"
SUDO ls $PCD/root/.config/ 2>/dev/null
echo ""
echo "--- root/.local/share 列出 ---"
SUDO ls $PCD/root/.local/share/ 2>/dev/null
echo ""
echo "--- /opt 内容 (PC root data 也有 /opt) ---"
SUDO ls $PCD/root/.opt/ 2>/dev/null
SUDO find $PCR/opt -maxdepth 2 -type d 2>/dev/null | head -20

echo ""
echo "==========================================" 
echo "C08: 勒索 (深度找)"
echo "=========================================="
SUDO find $PCD/root -maxdepth 5 -type f 2>/dev/null | grep -iE 'ransom|decrypt|\.locked|\.crypted|HOW.*RECOVER|README.*decrypt|你的文件|files_encrypted' | head -20
echo ""
SUDO find $PCD -maxdepth 6 -type f 2>/dev/null | grep -iE 'ransom|README.*hta|YOUR_FILES|hta\b' | head -10
echo ""
echo "--- 任意 .txt 在桌面/文档/下载 ---"
SUDO find $PCD/root/桌面 $PCD/root/文档 $PCD/root/下载 -type f 2>/dev/null | head -20
echo ""
echo "--- 文档目录 ---"
SUDO ls $PCD/root/文档/ 2>/dev/null
SUDO ls -la $PCD/root/文档/zhongyao/ 2>/dev/null

echo ""
echo "==========================================" 
echo "C03: 黄金 (re-search 邮件 + 全文)"
echo "=========================================="
SUDO ls $PCD/root/.config/deepin/deepin-mail/ 2>/dev/null
SUDO find $PCD/root/.config/deepin/deepin-mail -type f 2>/dev/null | head -20
SUDO grep -rao -l '黄金\|金条\|现金' $PCD/root 2>/dev/null | head -10
