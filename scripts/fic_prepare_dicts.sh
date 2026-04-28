#!/usr/bin/env bash
# 准备爆破字典 + 默认凭证清单
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

DICT_DIR="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/artifacts/dicts"
mkdir -p "$DICT_DIR"

# 1. rockyou (apt 包 wordlists 提供)
if [ ! -f /usr/share/wordlists/rockyou.txt ]; then
  if [ -f /usr/share/wordlists/rockyou.txt.gz ]; then
    SUDO gunzip -k /usr/share/wordlists/rockyou.txt.gz
  else
    SUDO apt-get install -y wordlists 2>&1 | tail -3
    [ -f /usr/share/wordlists/rockyou.txt.gz ] && SUDO gunzip -k /usr/share/wordlists/rockyou.txt.gz
  fi
fi

# 2. 默认凭证（FIC 实战常见）
cat > "$DICT_DIR/common_passwords.txt" <<'EOF'
admin
password
123456
12345678
1234567890
qwerty
root
toor
admin123
password123
admin@123
P@ssw0rd
abc123
test
test123
guest
user
user123
windows
linux
ubuntu
centos
debian
mysql
redis
mongodb
postgres
oracle
sa
hadoop
elastic
docker
kubernetes
jenkins
gitlab
nexus
admin1234
123456789
000000
111111
666666
888888
woshinidie
zaq12wsx
qaz123
asd123
123qwe
EOF

cat > "$DICT_DIR/default_creds.txt" <<'EOF'
# 服务名:用户:密码 (FIC 常见默认凭证)
ssh:root:
ssh:root:root
ssh:root:123456
ssh:root:password
ssh:root:toor
ssh:admin:admin
mysql:root:
mysql:root:root
mysql:root:123456
mysql:root:password
redis::
redis::password
redis::123456
mongodb:admin:admin
mongodb:root:root
postgres:postgres:postgres
postgres:postgres:123456
elastic:elastic:changeme
rabbitmq:guest:guest
ftp:anonymous:
ftp:ftp:ftp
tomcat:tomcat:tomcat
tomcat:admin:admin
jenkins:admin:admin
gitlab:root:5iveL!fe
gitlab:root:password
esxi:root:
esxi:root:vmware
esxi:root:VMware1!
openwrt:root:
openwrt:root:password
baota:admin:admin8
rocketchat:admin:admin
EOF

# 3. ESXi/VMware 常见密码
cat > "$DICT_DIR/esxi_passwords.txt" <<'EOF'
vmware
VMware1!
vmware123
esxi
ESXi123
root
admin
password
123456
P@ssw0rd
EOF

# 4. CMS / 应用密码
cat > "$DICT_DIR/cms_passwords.txt" <<'EOF'
admin
admin123
admin888
admin@123
admin@2024
admin@2025
admin@2026
ruoyi
ruoyi123
若依
123456
password
P@ssw0rd
EOF

echo "===== 字典准备完成 ====="
ls -la "$DICT_DIR"
echo ""
echo "rockyou.txt 行数:"
wc -l /usr/share/wordlists/rockyou.txt 2>/dev/null || echo "(rockyou 未就绪)"
