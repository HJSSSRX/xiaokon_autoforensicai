#!/bin/bash

echo '=== facefusion 寻找 ==='
sudo find /mnt/win_c -maxdepth 6 -iname 'facefusion*' 2>/dev/null | head -20
sudo find /mnt/win_c -iname 'facefusion.ini' 2>/dev/null | head

echo
echo '=== http--localhost5001 提示 AI 换脸 Web UI port ==='
# Recent 中 http--localhost5001-.lnk 指向 AI 换脸 WebUI
ls -la '/mnt/win_c/Users/起早王/AppData/Roaming/Microsoft/Windows/Recent/http--localhost5001-.lnk' 2>&1

echo
echo '=== 解析 facefusion lnk  ==='
# 简单 strings 找 target
for f in '/mnt/win_c/Users/起早王/AppData/Roaming/Microsoft/Windows/Recent/facefusion_3.1.1.lnk' \
         '/mnt/win_c/Users/起早王/AppData/Roaming/Microsoft/Windows/Recent/facefusion_3.1.10.lnk' \
         '/mnt/win_c/Users/起早王/AppData/Roaming/Microsoft/Windows/Recent/gguf.lnk' \
         '/mnt/win_c/Users/起早王/AppData/Roaming/Microsoft/Windows/Recent/conf.lnk' \
         '/mnt/win_c/Users/起早王/AppData/Roaming/Microsoft/Windows/Recent/http--localhost5001-.lnk'; do
    echo "## $(basename $f)"
    sudo strings "$f" 2>/dev/null | grep -iE ':\\|http|\.gguf|\.onnx|\.exe' | head -5
done

echo
echo '=== Chromium history url contains facefusion ==='
sqlite3 /tmp/edge_hist.sqlite "SELECT url, title FROM urls WHERE url LIKE '%5001%' OR url LIKE '%facefusion%' OR url LIKE '%roop%' LIMIT 20;"

echo
echo '=== Chromium downloads ==='
sqlite3 /tmp/edge_hist.sqlite "SELECT target_path, tab_url FROM downloads ORDER BY start_time DESC LIMIT 30;" 2>&1

echo
echo '=== 找 facefusion config / Model ==='
sudo find /mnt/win_c -maxdepth 6 -iname 'config.ini' -path '*facefusion*' 2>/dev/null | head
sudo find /mnt/win_c -maxdepth 6 -type d -iname 'facefusion*' 2>/dev/null | head