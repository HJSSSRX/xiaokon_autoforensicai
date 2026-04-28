#!/usr/bin/env bash
cd /tmp/fic_extract/zhongyao
for f in *.et; do
  echo ""
  echo "================ $f ================"
  file "$f"
  unzip -l "$f" 2>&1 | head -10
done

echo ""
echo "================ 解压 保险箱的秘密.et ================"
cd /tmp/fic_extract
mkdir -p baoxiangxiang
# 用 fileglob 避开中文
for f in zhongyao/*.et; do
  # 看每个 et 是否是 zip
  if file "$f" | grep -q 'Zip'; then
    name=$(basename "$f" .et)
    mkdir -p "et_unzip/$name"
    unzip -o -q "$f" -d "et_unzip/$name/"
    echo "解压: $name"
  fi
done

echo ""
echo "================ 各 et 文件内容（sharedStrings.xml） ================"
for d in et_unzip/*/; do
  echo ""
  echo "--- $d ---"
  ls "$d" 2>/dev/null
  ls "${d}xl/" 2>/dev/null
done
