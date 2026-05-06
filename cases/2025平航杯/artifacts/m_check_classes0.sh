#!/bin/bash
CJ=/tmp/phone/trojan/apk/assets/classes0.jar
ls -la $CJ
head -c 32 $CJ | xxd
file $CJ
echo '=== try unzip ==='
unzip -l $CJ 2>&1 | head -10