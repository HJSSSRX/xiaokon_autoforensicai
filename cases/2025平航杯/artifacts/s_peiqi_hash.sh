#!/bin/bash
F=/mnt/server/www/wwwroot/www.tpshop.com/peiqi.php
echo '== file size and meta =='
sudo wc -c "$F"
sudo stat -c '%s %y %W' "$F"
echo
echo '== xxd first 100 bytes =='
sudo xxd "$F" | head -5
echo
echo '== content =='
sudo cat "$F"
echo
echo '== sha256 (lower) =='
sudo sha256sum "$F"
echo
echo '== sha256 (UPPER) =='
sudo sha256sum "$F" | awk '{print toupper($1)}'
echo
echo '== md5 =='
sudo md5sum "$F"