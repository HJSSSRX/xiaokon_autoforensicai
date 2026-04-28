#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
ANS="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared/answers"
ROOT="/tmp/srv_root/@rootfs"
HIST="$ROOT/root/history"
MACCMS="$ROOT/var/www/html/maccms10"

cat > "$ANS/S06_main_srv_icp.md" <<'A'
## S06 — 网站设置的 ICP 备案号

> 该网站设置的icp备案号为

**答案**: `icp1919810`  **置信度**: 高

### 解析

**识别**: maccms10 站点配置存储在 `application/extra/maccms.php`（同一文件包含 db、site、app 三大节）。

**提取+分析**:
```bash
sudo cat /tmp/srv_root/@rootfs/var/www/html/maccms10/application/extra/maccms.php
```

`site` 节关键字段：
```
'site_name' => '免费短视频分享大全 - 大中国',
'site_url'  => 'www.2026fic.forensix',
'site_icp'  => 'icp1919810',          <- ICP 备案号
'site_qq'   => '4790286501',
'site_email'=> 'lianhong@forensix.cn',
```

`site_icp` 即"网站 ICP 备案号"配置项。

### 不作弊声明
- 数据来源: 检材3 服务器 maccms10/application/extra/maccms.php
- 工具: cat
- 脚本: scripts/fic_save_c02_more.sh
A

# 改进 S07 答案附带 maccms.php 完整证据
cat > "$ANS/S07_main_srv_main_domain.md" <<'A'
## S07 — 该网站设置的主域名

> 该网站设置的主域名为

**答案**: `www.2026fic.forensix`  **置信度**: 高

### 解析

**提取**:
```bash
sudo cat /tmp/srv_root/@rootfs/var/www/html/maccms10/application/extra/maccms.php
```

`site` 节：
```
'site_url'    => 'www.2026fic.forensix',     <- 主域名
'site_wapurl' => 'wap.2026fic.forensix',     <- 移动端域名
'site_email'  => 'lianhong@forensix.cn',
```

`site_url` 即 maccms 中"网站主域名"配置项。

### 不作弊声明
- 数据来源: 检材3 服务器
- 工具: cat
- 脚本: scripts/fic_save_c02_more.sh
A

echo "Saved S06 + 重写 S07"

echo ""
echo "==========================================" 
echo "S10: maccms.conf 伪静态规则 sm3 哈希"
echo "=========================================="
SUDO ls "$MACCMS/说明文档/伪静态规则/"
echo ""
echo "--- maccms.conf 内容 ---"
SUDO cat "$MACCMS/说明文档/伪静态规则/maccms.conf"
echo ""
echo "--- maccms.conf 文件 sm3 ---"
# openssl 默认不支持 sm3，但 openssl 1.1.1+ 支持 sm3
SUDO bash -c "openssl dgst -sm3 \"$MACCMS/说明文档/伪静态规则/maccms.conf\" 2>&1"
echo ""
echo "--- gmssl / 自己实现 sm3 ---"
which gmssl
python3 -c "
import hashlib
# 看 hashlib 是否支持 sm3
algos = hashlib.algorithms_available
print('SM3 可用:', 'sm3' in algos)
if 'sm3' in algos:
    with open('$MACCMS/说明文档/伪静态规则/maccms.conf', 'rb') as f:
        h = hashlib.new('sm3')
        h.update(f.read())
        print('sm3:', h.hexdigest())
"

echo ""
echo "==========================================" 
echo "S08: maccms 分类 (mac_type 表)"
echo "=========================================="
echo "--- application/extra/maccms.php 中 cat 部分 ---"
SUDO cat "$MACCMS/application/extra/maccms.php" | grep -A5 -i 'cat\|分类\|type' | head -30
echo ""
echo "--- 所有 extra/*.php ---"
SUDO ls $MACCMS/application/extra/

echo ""
echo "==========================================" 
echo "S13: TiDB 4000 端口（看 docker 容器 u24 内是否有 tidb）"
echo "=========================================="
SUDO ls $ROOT/data/containers/ | head
SUDO bash -c 'for f in $ROOT/data/containers/*/config.v2.json; do
  jq "{Name: .Name, Image: .Config.Image, ExposedPorts: .Config.ExposedPorts, Cmd: .Config.Cmd, Created: .Created}" "$f"
done' 2>/dev/null
echo ""
echo "--- 容器 u24 mounts/log ---"
SUDO ls $ROOT/data/containers/b8a338*/ 2>/dev/null
SUDO cat $ROOT/data/containers/b8a338*/hostconfig.json 2>/dev/null | jq '.PortBindings, .Binds' 2>/dev/null
echo ""
echo "--- u24 容器跑啥（log 末尾）---"
SUDO tail -20 $ROOT/data/containers/b8a338*/b8a338*-json.log 2>/dev/null
SUDO ls $ROOT/data/containers/b8a338*/ 2>/dev/null

echo ""
echo "==========================================" 
echo "S17: 通过 dpkg 看安装的数据库"
echo "=========================================="
SUDO grep -E ' install (mariadb|mysql|postgresql|redis|mongo|tidb|memcache|sqlite)' $ROOT/var/log/dpkg.log 2>/dev/null | head -20
echo ""
SUDO dpkg --root=$ROOT -l 2>/dev/null | grep -iE 'mariadb|mysql|postgres|redis|mongo|tidb' | head -20

echo ""
echo "==========================================" 
echo "I03: ngrok 详细域名（agent 客户端历史 / nginx Host 头）"
echo "=========================================="
echo "--- nginx access.log 中 Host 头不是 IP 的请求 ---"
SUDO awk -F'"' '{print $2}' $ROOT/var/log/nginx/access.log 2>/dev/null | grep -v '^$' | sort -u | head -20
echo ""
echo "--- ngrok 访问 ---"
SUDO grep -i 'ngrok' $ROOT/var/log/nginx/access.log 2>/dev/null | head
SUDO awk '$1 !~ /^192\./ && $1 !~ /^10\./ && $1 !~ /^127\./' $ROOT/var/log/nginx/access.log 2>/dev/null | head -10
