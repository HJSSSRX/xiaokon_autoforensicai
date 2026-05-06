#!/bin/bash
PCAP="/mnt/f/TEXT(important)/Jian cai/2025平航杯/USBPcap"
tshark -r "$PCAP" -Y 'usb.src=="2.4.1" && usb.data_len==37' -c 2 -x 2>&1 | head -60
echo '----'
# try full verbose on frame 117
tshark -r "$PCAP" -Y 'frame.number==117' -V 2>/dev/null | head -80