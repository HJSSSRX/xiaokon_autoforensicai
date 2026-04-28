#!/usr/bin/env bash
echo "=== pass8.csv ==="
cat /tmp/fic_extract/et_csv/pass8.csv
echo "[end]"
echo ""
echo "=== OLE 流 ==="
python3 << 'PYEOF'
import olefile
files = ["pass1.et","pass3.et","pass5.et","pass6.et","pass8.et"]
for f in files:
    p = "/tmp/fic_extract/zhongyao/" + f
    o = olefile.OleFileIO(p)
    streams = [s[0] for s in o.listdir()]
    print(f"{f}: {streams}")
    o.close()
PYEOF
echo ""
echo "=== 保险箱的秘密 ==="
python3 -c "
import olefile, glob
for p in glob.glob('/tmp/fic_extract/zhongyao/*.et'):
    o = olefile.OleFileIO(p)
    streams = [s[0] for s in o.listdir()]
    print(p.split('/')[-1], streams)
    o.close()
"
