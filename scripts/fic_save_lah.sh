#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
ANS="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared/answers"

# 落盘 S05 + S07
cat > "$ANS/S05_main_srv_admin_entry.md" <<'A'
## S05 — 网站后台管理入口对应的文件名

> 该网站后台管理入口对应的文件名为

**答案**: `user.php`  **置信度**: 高

### 解析

**识别**: maccms10 默认后台入口为 `admin.php`，但本环境 `/var/www/html/maccms10/` 下**不存在 admin.php**，仅存在 `index.php`、`api.php`、`install.php`、`user.php`。说明管理员重命名/重定向了后台入口。

**提取+分析**:

查 nginx access.log 找实际后台访问记录：
```bash
sudo tail -30 /tmp/srv_root/@rootfs/var/log/nginx/access.log
```

输出（截选）：
```
192.168.226.1 - - [16/Apr/2026:03:13:14 -0400] "GET /user.php/admin/index/checkcache.html?... HTTP/1.1" 200 33 "http://192.168.226.128/user.php/admin/index/index.html" "Mozilla/5.0 ..."
```

URL `/user.php/admin/index/index.html` 是 ThinkPHP 风格的后台路由，入口文件即 `user.php`。配合 nginx site 配置中的重写规则：
```
rewrite ^/user.php(.*)$ /user.php?s=$1 last;
```
也将 `user.php` 视作主入口之一。

### 不作弊声明
- 数据来源: 检材3 服务器 nginx access.log
- 工具: tail, grep
- 脚本: scripts/fic_attack_batch5.sh
A

cat > "$ANS/S07_main_srv_main_domain.md" <<'A'
## S07 — 该网站设置的主域名

> 该网站设置的主域名为

**答案**: `www.2026fic.forensix`  **置信度**: 高

### 解析

**识别**: maccms10 网站主域名通常存于 `application/extra/site.php` 或数据库 `mac_config` 表的 `site_url` 配置项。

**提取+分析**:
```bash
sudo grep -rh 'site_url\|wap_domain\|main_domain' \
  /tmp/srv_root/@rootfs/root/history/var/www/html/maccms10/application/extra/ 2>/dev/null
```

输出关键行：
```
'site_url' => 'www.2026fic.forensix',
```

`site_url` 是 maccms 中"网站主域名"配置项。

### 不作弊声明
- 数据来源: 检材3 服务器 btrfs 快照 /root/history/var/www/html/maccms10/application/extra/
- 工具: grep
- 脚本: scripts/fic_attack_batch5.sh
A

echo "已存 S05, S07"

echo ""
echo "==========================================" 
echo "lah 用户家目录（李安弘）"
echo "=========================================="
SUDO ls -la /tmp/pc_data/home/lah/ 2>/dev/null | head -40
SUDO find /tmp/pc_data/home/lah -maxdepth 3 -type d 2>/dev/null | head -50

echo ""
echo "--- lah 桌面 ---"
SUDO ls -la /tmp/pc_data/home/lah/桌面/ 2>/dev/null
SUDO ls /tmp/pc_data/home/lah/Desktop/ 2>/dev/null

echo ""
echo "--- lah 文档 ---"
SUDO ls /tmp/pc_data/home/lah/文档/ 2>/dev/null
SUDO ls /tmp/pc_data/home/lah/Documents/ 2>/dev/null

echo ""
echo "--- lah .config ---"
SUDO ls /tmp/pc_data/home/lah/.config/ 2>/dev/null

echo ""
echo "--- lah bash_history ---"
SUDO cat /tmp/pc_data/home/lah/.bash_history 2>/dev/null | tail -50

echo ""
echo "==========================================" 
echo "C05: VPN 软件查找（lah 家目录 + root .config）"
echo "=========================================="
SUDO find /tmp/pc_data/home/lah -maxdepth 5 -iname '*clash*' -o -iname '*v2ray*' -o -iname '*v2rayN*' -o -iname '*shadowsocks*' -o -iname '*trojan*' -o -iname '*Qv2ray*' 2>/dev/null | head -20
echo ""
SUDO find /tmp/pc_data/root/.config -maxdepth 3 -iname '*clash*' -o -iname '*v2ray*' -o -iname '*shadowsocks*' -o -iname '*proxy*' 2>/dev/null | head -10
echo ""
echo "--- /opt ---"
SUDO ls /tmp/pc_data/opt/ 2>/dev/null

echo ""
echo "==========================================" 
echo "C09/C10: 保险柜编号+密码（lah 家目录关键词搜索）"
echo "=========================================="
SUDO grep -rilE '保险柜|safe|保险箱|金条|黄金' /tmp/pc_data/home/lah/ 2>/dev/null | head -10
SUDO grep -rilE '保险柜|safe|保险箱' /tmp/pc_data/root/文档/ 2>/dev/null | head -10
echo ""
echo "--- zhongyao 文件夹 ---"
SUDO ls -la /tmp/pc_data/root/文档/zhongyao/ 2>/dev/null

echo ""
echo "==========================================" 
echo "C06/C07: AI 软件（找 ollama/lm-studio/Cherry/AnythingLLM/Chatbox）"
echo "=========================================="
SUDO find /tmp/pc_data/home/lah -maxdepth 5 -iname '*ollama*' -o -iname '*lm-studio*' -o -iname '*chatbox*' -o -iname '*cherry*' -o -iname '*chatgpt*' -o -iname '*anythingllm*' 2>/dev/null | head -20
SUDO find /tmp/pc_data/opt /tmp/pc_data/root -maxdepth 4 -iname '*ollama*' -o -iname '*lm-studio*' -o -iname '*chatbox*' 2>/dev/null | head -10

echo ""
echo "==========================================" 
echo "C02: 邮件（Thunderbird/邮件客户端）"
echo "=========================================="
SUDO ls /tmp/pc_data/home/lah/.thunderbird/ 2>/dev/null
SUDO find /tmp/pc_data/home/lah -maxdepth 4 -name '*.eml' -o -name 'Inbox*' -o -name 'mail.db' 2>/dev/null | head -10
