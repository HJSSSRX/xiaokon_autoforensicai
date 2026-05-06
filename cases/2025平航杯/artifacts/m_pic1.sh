#!/bin/bash
PIC=/tmp/phone/puzzle_apk/res/drawable-hdpi-v4/pic1.jpg
file "$PIC"
echo
echo '=== strings ==='
strings -n 6 "$PIC" | head -30
echo
echo '=== tail of file (should be FFD9) ==='
xxd "$PIC" | tail -10
echo
echo '=== look for FFD9 marker and trailing data ==='
python3 -c "
data=open('$PIC','rb').read()
idx=data.rfind(b'\xFF\xD9')
print(f'FFD9 at offset {idx}, file size {len(data)}, trailing bytes: {len(data)-idx-2}')
if idx+2 < len(data):
    print('Trailing data:', data[idx+2:idx+200])
"
echo
echo '=== exiftool ==='
which exiftool || apt-get install -y libimage-exiftool-perl 2>&1 | tail -3
exiftool "$PIC" 2>&1 | head -30