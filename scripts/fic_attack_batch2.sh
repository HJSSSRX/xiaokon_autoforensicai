#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
ROOT="/tmp/srv_root/@rootfs"
MACCMS="$ROOT/var/www/html/maccms10"

echo "==========================================" 
echo "S03: docker 最新镜像创建时间（实际 docker root = /data）"
echo "=========================================="
echo "--- imagedb metadata ---"
SUDO ls $ROOT/data/image/ 2>/dev/null
SUDO ls $ROOT/data/image/overlay2/imagedb/content/sha256/ 2>/dev/null | head
echo ""
COUNT=$(SUDO ls $ROOT/data/image/overlay2/imagedb/content/sha256/ 2>/dev/null | wc -l)
echo "镜像数量: $COUNT"
echo ""
echo "--- 各镜像 created 时间排序 ---"
SUDO bash -c "for f in $ROOT/data/image/overlay2/imagedb/content/sha256/*; do
  jq -r '.created' \"\$f\" 2>/dev/null
done" | sort -r | head -5
echo ""
echo "--- 各镜像详情（top 3 by created） ---"
SUDO bash -c "for f in $ROOT/data/image/overlay2/imagedb/content/sha256/*; do
  CREATED=\$(jq -r '.created' \"\$f\" 2>/dev/null)
  IMG=\$(basename \"\$f\")
  TAGS=\$(jq -r '.config.Labels // {} | to_entries | map(.value) | join(\",\")' \"\$f\" 2>/dev/null)
  ENV=\$(jq -r '.config.Env // [] | join(\",\")' \"\$f\" 2>/dev/null | head -c 100)
  echo \"\$CREATED \$IMG\"
done" | sort -r | head -5

echo ""
echo "--- repositories.json (镜像名/标签) ---"
SUDO cat $ROOT/data/image/overlay2/repositories.json 2>/dev/null | jq '.' 2>/dev/null

echo ""
echo "==========================================" 
echo "S05/S06/S07: maccms10 后台/ICP/主域名"
echo "=========================================="
SUDO ls $MACCMS/ 2>/dev/null
echo ""
echo "--- maccms 入口文件 ---"
SUDO ls $MACCMS/*.php 2>/dev/null
echo ""
echo "--- application/admin/ 入口 ---"
SUDO ls $MACCMS/application/ 2>/dev/null
SUDO grep -rh 'admin' $MACCMS/index.php 2>/dev/null | head -5
echo ""
echo "--- maccms config 文件 ---"
SUDO find $MACCMS/application -name 'config.php' -o -name 'database.php' 2>/dev/null | head
echo ""
echo "--- application/extra/ 配置目录 ---"
SUDO ls $MACCMS/application/extra/ 2>/dev/null
echo ""
echo "--- ICP / 域名（grep config）---"
SUDO grep -rh -E 'icp|备案|domain|主域' $MACCMS/application/ 2>/dev/null | head -10
echo ""
echo "--- maccms 后台路径配置（默认 admin.php，可能改名） ---"
# maccms 在 /application/extra/route.php 或者数据库 mac_config 里
SUDO cat $MACCMS/application/extra/admin.php 2>/dev/null | head
SUDO cat $MACCMS/application/extra/route.php 2>/dev/null
SUDO cat $MACCMS/application/extra/site.php 2>/dev/null | head -30

echo ""
echo "==========================================" 
echo "S11: maccms 关联数据库 IP"
echo "=========================================="
SUDO find $MACCMS/application -name 'database.php' -exec sudo cat {} \; 2>/dev/null

echo ""
echo "==========================================" 
echo "S13: 4000 端口数据库（TiDB）版本"
echo "=========================================="
echo "--- LXC mytidb 容器内 TiDB 二进制 ---"
SUDO find $ROOT/var/lib/lxc/mytidb/rootfs -name 'tidb-server' -o -name 'pd-server' -o -name 'tikv-server' 2>/dev/null | head
echo ""
SUDO ls $ROOT/var/lib/lxc/mytidb/rootfs/root/ 2>/dev/null
SUDO ls $ROOT/var/lib/lxc/mytidb/rootfs/usr/local/ 2>/dev/null
SUDO ls $ROOT/var/lib/lxc/mytidb/rootfs/opt/ 2>/dev/null
echo ""
echo "--- 找 TiDB 启动脚本/配置 ---"
SUDO find $ROOT/var/lib/lxc/mytidb/rootfs -name '*tidb*' -type f 2>/dev/null | head -20

echo ""
echo "==========================================" 
echo "S07: nginx 服务器名 / I03: ngrok 配置"
echo "=========================================="
SUDO find $ROOT/etc/nginx -type f -exec grep -lH 'server_name' {} \; 2>/dev/null
echo ""
SUDO find $ROOT -name 'ngrok*' -type f 2>/dev/null | head -10
SUDO find $ROOT -name '.config' -type d -path '*ngrok*' 2>/dev/null | head
SUDO find $ROOT/home -name 'ngrok*' 2>/dev/null
SUDO find $ROOT/root -name 'ngrok*' 2>/dev/null
SUDO find $ROOT -name 'ngrok.yml' 2>/dev/null
