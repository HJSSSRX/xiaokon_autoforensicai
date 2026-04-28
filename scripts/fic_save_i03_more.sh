#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
ROOT="/tmp/srv_root/@rootfs"
ANS="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared/answers"
MACCMS="$ROOT/var/www/html/maccms10"

cat > "$ANS/I03_main_ngrok_domain.md" <<'A'
## I03 — ngrok 提供的域名

> ngrok提供的域名为

**答案**: `blemish-junior-unengaged.ngrok-free.dev`  **置信度**: 高

### 解析

**识别**: 根 bash_history 显示 root 用过 `ngrok http 80`，将本地 80 端口（nginx）通过 ngrok 暴露到公网。ngrok 免费版会随机分配一个 `xxx-yyy-zzz.ngrok-free.dev` 域名给你。当通过 ngrok 域名访问时，浏览器请求里 Referer 头会带上完整 ngrok URL。

**提取**:
```bash
sudo grep 'ngrok' /tmp/srv_root/@rootfs/var/log/nginx/access.log.1 | head -5
```

输出关键行（截选）：
```
::1 - - [15/Apr/2026:03:55:47 -0400] "GET /template/001tep/html/style/css/v2-607838a2ee.css HTTP/1.1" 200 60126 "https://blemish-junior-unengaged.ngrok-free.dev/" "Mozilla/5.0 ..."
```

**分析+验证**:

- Referer 字段完整 URL: `https://blemish-junior-unengaged.ngrok-free.dev/`
- ngrok 免费版域名后缀格式：`<adj>-<adj>-<adj>.ngrok-free.dev`，本例 `blemish-junior-unengaged` 是三词组合
- 整个 access.log.1 中所有 ngrok-free 出现都是同一个域名（5+ 条命中），确认无歧义

**域名**：`blemish-junior-unengaged.ngrok-free.dev`

### 不作弊声明
- 数据来源: 检材3 服务器 nginx access.log.1（已轮转的访问日志）
- 工具: grep
- 脚本: scripts/fic_attack_batch7.sh + fic_attack_batch8.sh
A

echo "Saved I03"

echo ""
echo "==========================================" 
echo "S08: maccms 分类3 视频拼音（install.sql 查 mac_type）"
echo "=========================================="
SQL="$MACCMS/application/install/sql/install.sql"
SUDO ls -la "$SQL"
echo ""
echo "--- mac_type 相关 INSERT ---"
SUDO grep -E 'INSERT.*mac_type|CREATE.*mac_type' "$SQL" 2>/dev/null | head -5
echo ""
echo "--- mac_type INSERT 完整（前 5 条 type_id） ---"
SUDO sed -n '/INSERT INTO `mac_type`/,/);/p' "$SQL" 2>/dev/null | head -50

echo ""
echo "==========================================" 
echo "S08 进一步：从 maccms 数据库直接读 mac_type（如果有 SQL dump）"
echo "=========================================="
SUDO find $ROOT/var $ROOT/root -name 'mac2*' -o -name 'maccms*.sql' -o -name '*.sql.gz' 2>/dev/null | head -10
echo ""
echo "--- Redis 缓存里也可能有 ---"
SUDO ls $ROOT/var/lib/redis/ 2>/dev/null
SUDO find $ROOT -name 'dump.rdb' 2>/dev/null | head

echo ""
echo "==========================================" 
echo "S09: 站点设置页面前端模板"
echo "=========================================="
echo "--- application/admin/view 里 site/system 模板 ---"
SUDO find $MACCMS/application/admin/view -type d | head -20
SUDO ls $MACCMS/application/admin/view/system/ 2>/dev/null
SUDO ls $MACCMS/application/admin/view/site/ 2>/dev/null
echo ""
echo "--- view_new (新版后台模板) ---"
SUDO ls $MACCMS/application/admin/view_new/ 2>/dev/null
SUDO find $MACCMS/application/admin/view_new -name '*.html' | head -10
echo ""
echo "--- 站点设置页面具体 ---"
SUDO find $MACCMS/application/admin/view_new -name '*site*' -o -name '*system*' 2>/dev/null
SUDO find $MACCMS/application/admin/view -name '*site*' -o -name '*system*' 2>/dev/null

echo ""
echo "==========================================" 
echo "C04: APK 下载链接（推广设计图）"
echo "=========================================="
echo "--- root 桌面 + Pictures + 图片 ---"
SUDO ls /tmp/pc_data/root/桌面/ 2>/dev/null
SUDO ls /tmp/pc_data/root/Pictures/ 2>/dev/null
SUDO ls /tmp/pc_data/root/图片/ 2>/dev/null
echo ""
echo "--- 下载/Downloads ---"
SUDO ls /tmp/pc_data/root/下载/ 2>/dev/null
SUDO ls /tmp/pc_data/root/Downloads/ 2>/dev/null

echo ""
echo "==========================================" 
echo "C06/C07: AI 软件 配置（lah用户/root用户）"
echo "=========================================="
SUDO find /tmp/pc_data/root/.config -maxdepth 3 -type d 2>/dev/null | head -30
SUDO find /tmp/pc_data/home/lah/.config -maxdepth 3 -type d 2>/dev/null | head -20
echo ""
echo "--- cef_user_data 是哪个 app？ ---"
SUDO ls /tmp/pc_data/root/.config/cef_user_data/ 2>/dev/null
echo ""
echo "--- cpis 是啥 ---"
SUDO ls /tmp/pc_data/root/.config/cpis/ 2>/dev/null
echo ""
echo "--- LibreOffice 装好了吗 ---"
command -v libreoffice && command -v soffice
