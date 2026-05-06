#!/bin/bash
set -e
SRC=/mnt/f/cloud/DD/cases/2025平航杯/wp_batches
DST=/tmp/afad/knowledge/solved
mkdir -p $DST

# 工具：拼板块文件
build() {
    local prefix=$1
    local outname=$2
    local title=$3
    local tags=$4
    local tools=$5
    local difficulty=$6
    local total=$7
    local solved=$8
    local fname=$DST/2025pinghang_${outname}.md

    cat > $fname << EOF
---
tags: $tags
tools: $tools
category: $outname
difficulty: $difficulty
source: 2025平航杯_初赛
date: 2026-05-06
verified: solved_${solved}_of_${total}
---
# 2025 平航杯初赛 — $title

## Problem
2025 平航杯电子取证比赛初赛题目 ($total 题)。剧情：起早王（黑客）攻击倩倩的手机/服务器/计算机，在调查过程中梳理事件链。

## Evidence
EOF

    # 拼接所有批次
    for f in $SRC/${prefix}*.md; do
        echo >> $fname
        cat $f >> $fname
        echo >> $fname
    done
}

# N 板块 — 网络流量分析
build N network_traffic "网络流量分析 (N01-N09)" \
    '[network_forensics, pcap, bluetooth, wireshark, tshark, btatt, btcommon, mac_spoofing, manufacturer_data]' \
    '[wireshark, tshark, scapy, hashlib, python3]' \
    medium 9 8

# M 板块 — 手机取证
build M mobile_forensics "手机取证 (M01-M13)" \
    '[mobile_forensics, android, apk_analysis, malware, dex2jar, jadx, frida, qiniu, image_steganography, idcard_geo, imei]' \
    '[apktool, jadx, frida, dex2jar, exiftool, sqlite3]' \
    hard 13 11

# S 板块 — 服务器取证
build S server_forensics "服务器取证 (S01-S16)" \
    '[server_forensics, linux, trojan, thinkphp_rce, webshell, mysql, binlog, sql_window_function, intranet_scan, rdp, shadow_account]' \
    '[volatility, journalctl, mysqlbinlog, sqlite3, grep, jq]' \
    hard 16 16

# C 板块 — 计算机取证
build C computer_forensics "计算机取证 (C01-C21)" \
    '[computer_forensics, windows, registry, sticky_notes, sandboxie, sillytavern, microsoft_pinyin, bip39_mnemonic, metamask, sepolia_chain, ethereum_rpc, bitlocker]' \
    '[python_registry, sqlite3, eth_account, curl_jsonrpc, ewfmount, dislocker]' \
    hard 21 14

ls -la $DST/2025pinghang_*