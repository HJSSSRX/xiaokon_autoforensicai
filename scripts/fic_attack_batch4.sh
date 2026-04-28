#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
ROOT="/tmp/srv_root/@rootfs"
MACCMS="$ROOT/var/www/html/maccms10"

echo "==========================================" 
echo "/db/tidb 真实 LXC 容器（mytidb 的 rootfs）"
echo "=========================================="
SUDO ls -la $ROOT/db/ 2>/dev/null
SUDO ls -la $ROOT/db/tidb/ 2>/dev/null
SUDO ls $ROOT/db/tidb/etc/ 2>/dev/null | head -20
echo ""
echo "--- mytidb OS ---"
SUDO cat $ROOT/db/tidb/etc/os-release 2>/dev/null
echo ""
echo "--- mytidb 数据库二进制 ---"
SUDO find $ROOT/db/tidb/usr/sbin $ROOT/db/tidb/usr/bin $ROOT/db/tidb/opt $ROOT/db/tidb/usr/local -name 'mysqld' -o -name 'tidb-server' -o -name 'mariadbd' -o -name 'mongod' 2>/dev/null | head -10
echo ""
echo "--- mysql/tidb data 目录 ---"
SUDO ls $ROOT/db/tidb/var/lib/mysql/ 2>/dev/null | head -20
SUDO ls $ROOT/db/tidb/var/lib/postgresql/ 2>/dev/null
SUDO ls $ROOT/db/tidb/data/ 2>/dev/null | head
SUDO ls $ROOT/db/tidb/root/ 2>/dev/null
SUDO ls $ROOT/db/tidb/home/ 2>/dev/null

echo ""
echo "==========================================" 
echo "S13: 4000 端口数据库版本号"
echo "=========================================="
echo "--- mytidb 容器内 tidb 二进制 ---"
SUDO find $ROOT/db/tidb -name 'tidb-server' -o -name 'pd-server' -o -name 'tikv-server' 2>/dev/null
SUDO find $ROOT/db/tidb/root -type f 2>/dev/null | head -30
SUDO ls $ROOT/db/tidb/root/.tiup/ 2>/dev/null
SUDO ls $ROOT/db/tidb/usr/local/ 2>/dev/null
echo ""
echo "--- mytidb 容器跑啥服务（systemd） ---"
SUDO ls $ROOT/db/tidb/etc/systemd/system/multi-user.target.wants/ 2>/dev/null | head -20

echo ""
echo "==========================================" 
echo "S05/S06/S07/S08: maccms 数据库表（直接读 mysql data 文件）"
echo "=========================================="
echo "--- mac2 数据库的 mysql data 目录 ---"
SUDO ls $ROOT/db/tidb/var/lib/mysql/mac2/ 2>/dev/null | head -30
echo ""
echo "--- mac_config 表 (.ibd) 找 site 配置 ---"
SUDO ls $ROOT/db/tidb/var/lib/mysql/mac2/mac_config* 2>/dev/null
echo ""
# 用 strings 提取 mac_config.ibd 内容（需考虑 InnoDB 行格式）
echo "--- 字符串提取 mac_config（前 50 行） ---"
SUDO strings $ROOT/db/tidb/var/lib/mysql/mac2/mac_config.ibd 2>/dev/null | head -100

echo ""
echo "==========================================" 
echo "S17: 服务器安装的数据库服务（systemd 完整）"
echo "=========================================="
SUDO ls $ROOT/etc/systemd/system/multi-user.target.wants/ 2>/dev/null
echo ""
echo "--- 所有 service 文件 ---"
SUDO ls $ROOT/lib/systemd/system/ 2>/dev/null | grep -iE 'sql|mongo|redis|postgres|maria|tidb|tikv|cassandra|memcache|elastic|clickhouse|influx' 
echo ""
echo "--- /usr/sbin /usr/bin 数据库二进制 ---"
SUDO ls $ROOT/usr/sbin/ 2>/dev/null | grep -iE 'sql|mongo|redis|postgres|maria|tidb|tikv|elasticsearch|clickhouse|influx'
SUDO ls $ROOT/usr/bin/ 2>/dev/null | grep -iE 'sql|mongo|redis|postgres|maria|tidb|tikv|elasticsearch|clickhouse|influx'

echo ""
echo "==========================================" 
echo "S16: 文件系统未被使用"
echo "=========================================="
echo "--- 已使用的文件系统（fstab + 实际识别） ---"
SUDO cat $ROOT/etc/fstab | grep -v '^#' | awk '{print $3}' | sort -u
echo ""
echo "--- 已安装的 fs 工具 ---"
SUDO ls $ROOT/sbin/ 2>/dev/null | grep -iE 'mkfs|mount\.' | head -20
SUDO ls $ROOT/usr/sbin/ 2>/dev/null | grep -iE 'mkfs|mount\.' | head -20
echo ""
echo "--- ZFS 是否实际在用 ---"
SUDO ls $ROOT/etc/zfs/ 2>/dev/null
SUDO cat $ROOT/etc/zfs/zpool.cache 2>/dev/null | head -1
SUDO ls $ROOT/var/lib/zfs/ 2>/dev/null

echo ""
echo "==========================================" 
echo "C05: PC 上 VPN 软件代理端口"
echo "=========================================="
PC_ROOT="/tmp/pc_root"
echo "--- 查找 VPN 软件配置（V2Ray/Clash/Trojan/SS 等） ---"
SUDO find $PC_ROOT -maxdepth 6 \( -name 'config.json' -o -name 'config.yaml' -o -name 'config.yml' \) 2>/dev/null | head -20
echo ""
echo "--- /opt 第三方软件 ---"
SUDO ls $PC_ROOT/opt/ 2>/dev/null
echo ""
echo "--- /usr/local 第三方 ---"
SUDO ls $PC_ROOT/usr/local/ 2>/dev/null
echo ""
echo "--- 用户家目录的代理工具配置 ---"
SUDO ls -la $PC_ROOT/home/ 2>/dev/null
USERS=$(SUDO ls $PC_ROOT/home/ 2>/dev/null)
for U in $USERS; do
  echo "--- $U ---"
  SUDO find $PC_ROOT/home/$U -maxdepth 4 -type d \( -name 'clash*' -o -name 'v2ray*' -o -name 'shadowsocks*' -o -name 'trojan*' -o -name '.config' -o -name '*VPN*' -o -name '*proxy*' \) 2>/dev/null | head -10
done
