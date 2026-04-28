#!/usr/bin/env bash
# FIC2026 专项工具差距检查
# Usage: wsl -e bash /mnt/e/项目/自动化取证/scripts/fic_tools_check.sh

TOOLS=(
  # Java 逆向
  jadx
  # 密码爆破
  hashcat hydra john
  # 网络分析
  zeek tshark capinfos
  # 数据库
  mongo mongosh mysql redis-cli psql
  # 容器
  docker
  # 加密 zip 爆破
  pkcrack fcrackzip
  # 镜像/格式
  xxd file binwalk exiftool
  # 文件雕刻
  foremost photorec scalpel
  # 虚拟化
  qemu-img qemu-nbd vmware-mount
  # ESXi
  esxcfg-volume vmfs6-fuse vmfs-fuse
  # Office/PDF
  pdfinfo pdftotext libreoffice
  # 加密
  openssl gpg
  # 网络抓包
  ngrep
  # 邮件
  ripmime mu
  # 取证
  fls icat tsk_recover
  # AXIOM/火眼相关
  vol
  # APK
  apktool aapt
  # 钱包/PE
  pefile
)

OK=0; MISS=0; MISS_LIST=()
for t in "${TOOLS[@]}"; do
  if command -v "$t" >/dev/null 2>&1; then
    echo "OK : $t"
    OK=$((OK+1))
  else
    echo "-- : $t  (MISS)"
    MISS=$((MISS+1))
    MISS_LIST+=("$t")
  fi
done

echo ""
echo "===== Summary: $OK OK / $MISS MISS ====="
echo "Missing: ${MISS_LIST[*]}"
