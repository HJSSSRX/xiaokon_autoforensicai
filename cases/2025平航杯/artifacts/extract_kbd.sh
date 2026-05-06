#!/bin/bash
PCAP="/mnt/f/TEXT(important)/Jian cai/2025平航杯/USBPcap"
tshark -r "$PCAP" -Y 'usb.src=="2.4.1" && usb.data_len==37' -T fields -e frame.time_epoch -e usbhid.data 2>/dev/null > /tmp/kbd.tsv
wc -l /tmp/kbd.tsv
head -10 /tmp/kbd.tsv
echo '--- unique non-empty data (ignoring trailing zeros shown as hex bytes) ---'
awk -F"\t" '{print $2}' /tmp/kbd.tsv | sort -u | head -20