#!/usr/bin/env bash
echo "=== pass8.csv 内容 ==="
cat /tmp/fic_extract/et_csv/pass8.csv
echo "[end]"
echo ""
echo "=== 检查 OLE 流（看加密状态）==="
python3 << 'PYEOF'
import olefile
import os
files = ["pass1.et", "pass3.et", "pass5.et", "pass6.et", "pass8.et", "保险箱的秘密.et"]
for f in files:
    p = "/tmp/fic_extract/zhongyao/" + f
    if not os.path.exists(p):
        print(f"NOT FOUND: {p}")
        continue
    try:
        o = olefile.OleFileIO(p)
        streams = [s[0] for s in o.listdir()]
        is_enc = ("EncryptionInfo" in streams) or ("EncryptedPackage" in streams) or any('encrypt' in s.lower() for s in streams)
        print(f"{f}: streams={streams[:8]}, encrypted={is_enc}")
        o.close()
    except Exception as e:
        print(f"{f}: ERROR {e}")
PYEOF

echo ""
echo "=== 试 office2john（提取 hash 给 hashcat） ==="
which office2john
which office2john.py
find / -name 'office2john*' 2>/dev/null | head

echo ""
echo "=== 各 .et 文件大小和 head dump ==="
for f in pass1.et pass3.et pass5.et pass6.et pass8.et; do
  p="/tmp/fic_extract/zhongyao/$f"
  echo "--- $f ---"
  ls -la "$p"
  head -c 200 "$p" | od -c | head -3
done

echo ""
echo "=== 用 LibreOffice 试用密码 1, 3, 5, 6, 8 打开 ==="
# 试默认密码
for pw in 1 3 5 6 8 13568 168 1+3+5+6+8 86531; do
  echo ""
  echo "--- 尝试密码: $pw ---"
  rm -f /tmp/fic_extract/test_pwd.csv
  timeout 20 libreoffice --headless --norestore --convert-to csv --outdir /tmp/fic_extract --infilter='"Calc Office Open XML":"Office":"$pw":""' /tmp/fic_extract/zhongyao/pass1.et 2>&1 | tail -2
  if [ -f /tmp/fic_extract/pass1.csv ]; then
    SIZE=$(stat -c%s /tmp/fic_extract/pass1.csv)
    [ "$SIZE" -gt "1" ] && echo "*** 解开成功！密码: $pw ***" && cat /tmp/fic_extract/pass1.csv && break
  fi
done
