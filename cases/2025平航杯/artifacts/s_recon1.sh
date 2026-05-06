#!/bin/bash
S=/mnt/server

echo '=== S02 内核 ==='
ls $S/lib/modules/ 2>&1
cat $S/etc/redhat-release

echo
echo '=== S03 用户 ==='
awk -F: '$3>=1000 && $3<65534 {print $1,$3,$6,$7}' $S/etc/passwd

echo
echo '=== /home /root 内容 ==='
ls -la $S/home/ 2>&1
ls -la $S/root/ 2>&1

echo
echo '=== Trojan 配置 ==='
find $S/etc /opt /usr/local /root /home $S/patch -name 'trojan*' -o -name '*.json' 2>/dev/null | xargs -I{} bash -c 'f="{}"; [ -f "$f" ] && echo "## $f" && head -50 "$f" 2>/dev/null' 2>&1 | head -150

echo
echo '=== Look for trojan binary / service ==='
find $S -name 'trojan' -type f 2>/dev/null | head -10
find $S/etc/systemd $S/usr/lib/systemd -name '*trojan*' 2>/dev/null | head -5