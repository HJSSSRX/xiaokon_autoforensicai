#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

SUDO apt-get install -y tesseract-ocr tesseract-ocr-chi-sim tesseract-ocr-chi-tra 2>&1 | tail -5

command -v tesseract && tesseract --list-langs 2>&1 | head -10
