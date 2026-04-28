#!/usr/bin/env bash
# 后台跑：.et 密码爆破
# 步骤：1) office2john 提 hash  2) hashcat 跑字典+组合
set -e
LOG=/tmp/fic_extract/et_crack.log
echo "===== ET CRACK START $(date) =====" > $LOG

# 找 office2john
O2J=$(find / -name 'office2john*' 2>/dev/null | head -1)
echo "office2john: $O2J" | tee -a $LOG

mkdir -p /tmp/fic_extract/hashes
cd /tmp/fic_extract/zhongyao
for f in pass1.et pass3.et pass5.et pass6.et pass8.et 保险箱的秘密.et; do
  [ -f "$f" ] || continue
  echo "" | tee -a $LOG
  echo "===== $f =====" | tee -a $LOG
  if [ -n "$O2J" ]; then
    python3 "$O2J" "$f" > /tmp/fic_extract/hashes/${f%.et}.hash 2>>$LOG
    cat /tmp/fic_extract/hashes/${f%.et}.hash | tee -a $LOG
  fi
done

# 字典准备
DICT=/tmp/fic_extract/et_dict.txt
cat > $DICT <<EOF
1
3
5
6
8
13568
86531
168
135
13
35
56
68
135568
85631
8513
1+3+5+6+8
123456
000000
admin
password
lah
lianhong
lihongan
lihongan19851024
4790286501
icp1919810
2026fic
forensix
maccms
ngrok
EOF

# 用 john 跑（office hash 在 john 里支持更全）
echo "" | tee -a $LOG
echo "===== john crack =====" | tee -a $LOG
for h in /tmp/fic_extract/hashes/*.hash; do
  [ -s "$h" ] || continue
  echo "--- $h ---" | tee -a $LOG
  timeout 60 john --wordlist=$DICT "$h" 2>&1 | tee -a $LOG | tail -10
  john --show "$h" 2>&1 | tee -a $LOG
done

echo "" | tee -a $LOG
echo "===== ET CRACK DONE $(date) =====" | tee -a $LOG
