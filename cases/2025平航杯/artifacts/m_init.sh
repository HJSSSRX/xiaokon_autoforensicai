#!/bin/bash
ZIP="/mnt/f/TEXT(important)/Jian cai/2025平航杯/20250415_181118.zip"
mkdir -p /tmp/phone
cd /tmp/phone
unzip -o "$ZIP" '*/descript.xml' 2>&1 | tail -3
echo '---'
ls -la 20250415_181118/
echo '=== descript.xml content (head) ==='
head -80 20250415_181118/descript.xml