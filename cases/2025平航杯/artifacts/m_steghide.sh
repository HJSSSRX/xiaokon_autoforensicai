#!/bin/bash
PIC=/tmp/phone/puzzle_apk/res/drawable-hdpi-v4/pic1.jpg
which steghide || apt-get install -y steghide 2>&1 | tail -2

# Try empty password first then with M02 key
for pw in "" "Key_1n_the_P1c" "Key_in_the_Pic" "weZl_d0wn_sbwyz_" "D0you_f1nd_truth?"; do
    echo "=== steghide pw=[$pw] ==="
    rm -f /tmp/sg_out
    steghide extract -sf "$PIC" -p "$pw" -xf /tmp/sg_out -f 2>&1
    if [ -s /tmp/sg_out ]; then
        echo "--- contents ---"
        head -c 500 /tmp/sg_out
        echo
    fi
done