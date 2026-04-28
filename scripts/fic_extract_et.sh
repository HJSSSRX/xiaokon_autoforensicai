#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

EXTRACT="/tmp/fic_extract"
mkdir -p $EXTRACT/zhongyao

echo "===== 拷贝 .et 文件出来 ====="
SUDO cp /tmp/pc_data/root/文档/zhongyao/*.et $EXTRACT/zhongyao/ 2>&1
SUDO chown -R hjsssr:hjsssr $EXTRACT/zhongyao/
ls -la $EXTRACT/zhongyao/

echo ""
echo "===== 测试是否需要密码 ====="
for f in $EXTRACT/zhongyao/*.et; do
  echo ""
  echo "--- $f ---"
  file "$f"
  # 试 unzip 看是不是 zip
  unzip -l "$f" 2>&1 | head -5
done

echo ""
echo "===== 用 libreoffice 转 xlsx ====="
command -v libreoffice 2>&1 || echo "libreoffice not installed"
command -v soffice 2>&1 || echo "soffice not installed"
command -v ssconvert 2>&1 || echo "ssconvert not installed"

echo ""
echo "===== 如果是 zip + ooxml，直接读 xml ====="
for f in $EXTRACT/zhongyao/*.et; do
  echo ""
  echo "--- 解 $f ---"
  base=$(basename $f .et)
  mkdir -p $EXTRACT/zhongyao_unzip/$base
  unzip -o "$f" -d $EXTRACT/zhongyao_unzip/$base/ 2>&1 | head -3
  ls $EXTRACT/zhongyao_unzip/$base/ 2>/dev/null | head
done

echo ""
echo "===== 保险箱的秘密.et 详细内容 ====="
SECRET_DIR="$EXTRACT/zhongyao_unzip/保险箱的秘密"
if [ -d "$SECRET_DIR" ]; then
  ls -la $SECRET_DIR/
  ls -la $SECRET_DIR/xl/ 2>/dev/null
  echo ""
  echo "--- sharedStrings.xml ---"
  cat $SECRET_DIR/xl/sharedStrings.xml 2>/dev/null | head -200
  echo ""
  echo "--- sheet1.xml 数据 ---"
  cat $SECRET_DIR/xl/worksheets/sheet1.xml 2>/dev/null | head -200
fi
