#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

echo "==========================================" 
echo "用 LibreOffice 转 .et → csv（批量）"
echo "=========================================="
mkdir -p /tmp/fic_extract/et_csv
cd /tmp/fic_extract/zhongyao
for f in *.et; do
  echo ""
  echo "--- 转 $f ---"
  libreoffice --headless --convert-to csv --outdir /tmp/fic_extract/et_csv "$f" 2>&1 | tail -3
done

echo ""
ls -la /tmp/fic_extract/et_csv/

echo ""
echo "==========================================" 
echo "查看每个 csv 内容（C09/C10 在 保险箱的秘密）"
echo "=========================================="
for csv in /tmp/fic_extract/et_csv/*.csv; do
  echo ""
  echo "================ $csv ================"
  cat "$csv" | head -50
done

echo ""
echo "==========================================" 
echo "S08: 解压 maccms 数据库备份 sql.gz"
echo "=========================================="
ROOT="/tmp/srv_root/@rootfs"
MACCMS="$ROOT/var/www/html/maccms10"
mkdir -p /tmp/fic_extract/maccms_backup
echo ""
echo "--- 备份文件 ---"
SUDO find $MACCMS -name '*.sql.gz' 2>/dev/null
echo ""
echo "--- 解压并查 mac_type ---"
SUDO cp $MACCMS/template/YMYS002/application/data/backup/database/20210203-120519-1.sql.gz /tmp/fic_extract/maccms_backup/
gunzip -k /tmp/fic_extract/maccms_backup/20210203-120519-1.sql.gz 2>&1
ls -la /tmp/fic_extract/maccms_backup/
echo ""
echo "--- 查 mac_type INSERT 内容 ---"
grep -E 'INSERT INTO `mac_type`' /tmp/fic_extract/maccms_backup/20210203-120519-1.sql 2>/dev/null | head -3
echo ""
echo "--- mac_type 完整 INSERT ---"
sed -n '/INSERT INTO `mac_type`/,/);/p' /tmp/fic_extract/maccms_backup/20210203-120519-1.sql 2>/dev/null | head -100

echo ""
echo "==========================================" 
echo "S09: 站点设置页面前端源文件"
echo "=========================================="
echo "--- view_new/website/index.html  ---"
SUDO cat $MACCMS/application/admin/view_new/website/index.html 2>/dev/null | head -30
echo ""
echo "--- view_new/system/index.html ---"
SUDO ls $MACCMS/application/admin/view_new/system/ 2>/dev/null
SUDO cat $MACCMS/application/admin/view_new/system/index.html 2>/dev/null | head -30
echo ""
echo "--- 路由分析：哪些 controller 处理 site 设置 ---"
SUDO ls $MACCMS/application/admin/controller/ 2>/dev/null | head -30
SUDO grep -ril 'site_url\|站点\|网站设置' $MACCMS/application/admin/controller/ 2>/dev/null | head -5

echo ""
echo "==========================================" 
echo "C04: 推广设计图（OCR 9 张图片）"
echo "=========================================="
mkdir -p /tmp/fic_extract/promo_pics
SUDO cp /tmp/pc_data/root/Pictures/*.jpeg /tmp/fic_extract/promo_pics/ 2>/dev/null
SUDO chown hjsssr:hjsssr /tmp/fic_extract/promo_pics/*
ls -la /tmp/fic_extract/promo_pics/ | head
echo ""
echo "--- OCR 每张图找 APK 下载链接 ---"
for img in /tmp/fic_extract/promo_pics/*.jpeg; do
  echo ""
  echo "--- $img ---"
  tesseract "$img" - -l chi_sim+eng 2>/dev/null | grep -iE 'apk|http|download|下载|url|\.com|\.cn' | head -5
done
