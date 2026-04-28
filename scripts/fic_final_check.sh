#!/usr/bin/env bash
# FIC2026 赛前最终工具检查

echo "===== FIC2026 工具最终检查 ====="
echo ""

OK=0; MISS=0
chk() {
  if command -v "$1" >/dev/null 2>&1; then
    printf "  [OK]  %-20s %s\n" "$1" "$(which $1)"
    OK=$((OK+1))
  else
    printf "  [--]  %-20s MISSING\n" "$1"
    MISS=$((MISS+1))
  fi
}

echo "[1] 镜像挂载"
for t in ewfmount mmls fls icat tsk_recover qemu-img qemu-nbd vmfs-fuse losetup; do chk "$t"; done

echo ""
echo "[2] 网络分析"
for t in tshark capinfos zeek ngrep; do chk "$t"; done

echo ""
echo "[3] 数据库"
for t in sqlite3 mysql redis-cli mongosh; do chk "$t"; done

echo ""
echo "[4] 反编译/逆向"
for t in jadx apktool aapt yara r2 strings binwalk exiftool; do chk "$t"; done

echo ""
echo "[5] 爆破"
for t in hashcat hydra john fcrackzip; do chk "$t"; done

echo ""
echo "[6] 雕刻/恢复"
for t in foremost photorec testdisk; do chk "$t"; done

echo ""
echo "[7] PDF/Office"
for t in pdfinfo pdftotext; do chk "$t"; done

echo ""
echo "[8] OCR"
for t in tesseract; do chk "$t"; done

echo ""
echo "[9] 通用"
for t in curl wget jq xxd file 7z openssl gpg python3 git; do chk "$t"; done

echo ""
echo "[10] venv 内取证工具"
source $HOME/.venv-forensics/bin/activate 2>/dev/null
for t in vol androguard; do chk "$t"; done
deactivate 2>/dev/null

echo ""
echo "[11] Windows 侧 EZ Tools"
for f in MFTECmd EvtxECmd RECmd PECmd; do
  p="/mnt/e/项目/自动化取证/tools/EZ"
  if [ -f "$p/$f.exe" ] || [ -f "$p/${f}.exe" ] || ls "$p"/*/$f.exe 2>/dev/null >/dev/null; then
    printf "  [OK]  %-20s\n" "$f.exe"; OK=$((OK+1))
  else
    printf "  [--]  %-20s MISSING\n" "$f.exe"; MISS=$((MISS+1))
  fi
done

echo ""
echo "[12] jadx-gui (Windows)"
if [ -f "/mnt/e/项目/自动化取证/tools/jadx-gui/jadx-gui-1.5.5.exe" ]; then
  echo "  [OK]  jadx-gui-1.5.5.exe"; OK=$((OK+1))
else
  echo "  [--]  jadx-gui Windows MISSING"; MISS=$((MISS+1))
fi

echo ""
echo "[13] 字典"
DICT="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/artifacts/dicts"
for f in common_passwords default_creds esxi_passwords cms_passwords; do
  if [ -f "$DICT/$f.txt" ]; then
    cnt=$(wc -l < "$DICT/$f.txt")
    printf "  [OK]  %-25s %d lines\n" "$f.txt" "$cnt"; OK=$((OK+1))
  else
    printf "  [--]  %-25s MISSING\n" "$f.txt"; MISS=$((MISS+1))
  fi
done

echo ""
echo "[14] 关键文档"
for f in FIC2026_OPEN_SOP.md FIC2026_MULTI_WINDOW.md FIC2026_NEW_TOPICS.md AI_BRAIN/README.md AI_BRAIN/output_contract.md; do
  if [ -f "/mnt/e/项目/自动化取证/$f" ]; then
    printf "  [OK]  %s\n" "$f"; OK=$((OK+1))
  else
    printf "  [--]  %s MISSING\n" "$f"; MISS=$((MISS+1))
  fi
done

echo ""
echo "[15] 共享目录"
for d in shared/inbox shared/answers work_server work_pc work_phone artifacts wp_batches; do
  p="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/$d"
  if [ -d "$p" ]; then
    printf "  [OK]  %s\n" "$d"; OK=$((OK+1))
  else
    printf "  [--]  %s MISSING\n" "$d"; MISS=$((MISS+1))
  fi
done

echo ""
echo "==========================================="
echo "  PASS: $OK    FAIL: $MISS"
echo "==========================================="
[ "$MISS" -eq 0 ] && echo "全部就绪，可以开赛！" || echo "有 $MISS 项缺失，看上面 [--] 标记"
