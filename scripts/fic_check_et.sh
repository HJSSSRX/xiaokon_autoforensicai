#!/usr/bin/env bash
echo "=== pass8.csv ==="
cat /tmp/fic_extract/et_csv/pass8.csv
echo ""
echo "=== pass1-6 是空的吗？看字节 ==="
for f in pass1.csv pass3.csv pass5.csv pass6.csv; do
  echo "--- $f ---"
  cat /tmp/fic_extract/et_csv/$f
  echo "[end]"
  od -c /tmp/fic_extract/et_csv/$f | head -2
done
echo ""
echo "=== 保险箱的秘密.csv ==="
cat /tmp/fic_extract/et_csv/*.csv | tail -5
ls -la /tmp/fic_extract/et_csv/

echo ""
echo "=== 直接用 olefile / LibreOffice 检测加密 ==="
for f in /tmp/fic_extract/zhongyao/*.et; do
  echo ""
  echo "--- $f ---"
  python3 -c "
import olefile
try:
    o = olefile.OleFileIO('$f')
    print('OLE OK')
    streams = o.listdir()
    print('streams:', streams[:5])
    # 检查是否加密
    if o.exists('EncryptionInfo'):
        print('!! 加密 EncryptionInfo')
    if o.exists('EncryptedPackage'):
        print('!! 加密 EncryptedPackage')
    o.close()
except Exception as e:
    print('错误:', e)
"
done

echo ""
echo "=== mac_type 完整 INSERT ==="
grep -E 'INSERT INTO `mac_type` VALUES' /tmp/fic_extract/maccms_backup/20210203-120519-1.sql | head -30
