#!/bin/bash
PCAP="/mnt/f/TEXT(important)/Jian cai/2025平航杯/BLE"
# Sony company id (0x012d) data - real Sony earphones?
echo '=== 0x012d (Sony) data samples ==='
tshark -r "$PCAP" -Y 'btcommon.eir_ad.entry.company_id==0x012d' -T fields -e btle.advertising_address -e btcommon.eir_ad.entry.data 2>/dev/null | sort -u | head -5

# Xiaomi company id (0x038f) data - Xiaomi phone?
echo '=== 0x038f (Xiaomi) data samples ==='
tshark -r "$PCAP" -Y 'btcommon.eir_ad.entry.company_id==0x038f' -T fields -e btle.advertising_address -e btcommon.eir_ad.entry.data 2>/dev/null | sort -u | head -10

# All unique complete_local_name AND shortened_local_name
echo '=== device_name field types ==='
tshark -r "$PCAP" -Y 'btcommon.eir_ad.entry.device_name' -T fields -e btcommon.eir_ad.entry.type -e btcommon.eir_ad.entry.device_name 2>/dev/null | sort -u | awk -F"\t" '$2 ~ /^[A-Za-z0-9_. -]+$/ && length($2) >= 4' | head -20

# Strings with likely Chinese pinyin names (3 syllables of 1-5 chars each separated by space/underscore)
echo '=== strings matching pinyin-like 3-part names ==='
strings -n 6 "$PCAP" | grep -iE '^[A-Z][a-z]+_[A-Z][a-z]+_[A-Z][a-z]+' | sort -u | head -20
strings -n 6 "$PCAP" | grep -iE '^[A-Z][a-z]+ [A-Z][a-z]+ [A-Z][a-z]+' | sort -u | head -20

# search any ASCII string ≥8 chars with >=1 underscore
echo '=== underscore strings ==='
strings -n 8 "$PCAP" | grep '_' | sort -u | grep -vE '^(LE-|QQ_WF|Flipper|Nlipper|Flippe|PE-YQ|QR_WF|QQ_W)' | head -20