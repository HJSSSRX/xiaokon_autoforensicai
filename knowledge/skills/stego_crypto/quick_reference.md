# Steganography & Cryptography — Quick Reference

## File Identification
```bash
file {target}                            # Magic bytes detection
xxd {target} | head -20                  # Raw hex view
exiftool {target}                        # All metadata
strings {target}                         # ASCII strings
strings -e l {target}                    # UTF-16LE strings
binwalk {target}                         # Embedded files
binwalk -e {target}                      # Extract embedded files
```

## Steganography by File Type

### PNG
```bash
zsteg {file}                             # LSB (all channels)
zsteg {file} -a                          # Exhaustive LSB search
pngcheck -v {file}                       # Structure validation
# Check: IDAT anomalies, tEXt/zTXt chunks, palette tricks, IHDR manipulation
# CRC mismatch → try fixing image dimensions
python3 -c "
import struct, zlib
with open('{file}','rb') as f:
    data = f.read()
    # Check IHDR CRC
    ihdr = data[12:29]
    crc = struct.unpack('>I', data[29:33])[0]
    expected = zlib.crc32(data[12:29]) & 0xffffffff
    print(f'CRC match: {crc == expected}, stored: {crc:#x}, expected: {expected:#x}')
"
```

### JPEG/BMP
```bash
steghide extract -sf {file}              # Empty password
steghide extract -sf {file} -p {pass}    # With password
stegseek {file} rockyou.txt              # Brute-force password
steghide info {file}                     # Check if data is embedded
```

### Audio
```bash
sox {file} -n spectrogram -o spec.png    # Visual spectrogram
# Look for: SSTV signals, Morse code, DTMF tones, hidden images
# Tools: Audacity (GUI), sonic-visualiser
```

### ZIP/Archive
```bash
fcrackzip -D -p rockyou.txt -u {file}    # Dictionary attack
john --format=zip {hash_file}            # John with zip2john
zip2john {file} > hash.txt               # Extract hash
```

## Common Encodings
```bash
# Base64
echo -n "{data}" | base64 -d
# Base32
echo -n "{data}" | base32 -d
# Hex
echo -n "{hex}" | xxd -r -p
# URL encoding
python3 -c "import urllib.parse; print(urllib.parse.unquote('{data}'))"
# Binary
python3 -c "bits='{01100110...}'; print(''.join(chr(int(bits[i:i+8],2)) for i in range(0,len(bits),8)))"
# Morse code
python3 -c "
MORSE = {'.-':'A','-...':'B','-.-.':'C','-..':'D','.':'E','..-.':'F','--.':'G','....':'H','..':'I','.---':'J','-.-':'K','.-..':'L','--':'M','-.':'N','---':'O','.--.':'P','--.-':'Q','.-.':'R','...':'S','-':'T','..-':'U','...-':'V','.--':'W','-..-':'X','-.--':'Y','--..':'Z'}
msg = '{data}'.split(' / ')
print(''.join(''.join(MORSE.get(c,'?') for c in word.split()) for word in msg))
"
```

## Classical Ciphers
```bash
# Caesar / ROT
python3 -c "
ct = '{ciphertext}'
for shift in range(26):
    print(f'{shift}: ' + ''.join(chr((ord(c)-65+shift)%26+65) if c.isupper() else chr((ord(c)-97+shift)%26+97) if c.islower() else c for c in ct))
"

# Vigenere (known key)
python3 -c "
ct, key = '{ct}', '{key}'
pt = ''
ki = 0
for c in ct:
    if c.isalpha():
        shift = ord(key[ki % len(key)].upper()) - 65
        base = 65 if c.isupper() else 97
        pt += chr((ord(c) - base - shift) % 26 + base)
        ki += 1
    else:
        pt += c
print(pt)
"
```

## RSA Attacks
```bash
# Factor small n
python3 -c "from sympy import factorint; print(factorint({n}))"

# Wiener attack (small d)
# Fermat factorization (p ≈ q)
# Common modulus attack (same n, different e)
# Low exponent attack (e=3, small m)
# Hastad broadcast (same m, different n, e=3)

# rsactftool (automated)
rsactftool --publickey pub.pem --uncipherfile cipher.txt
rsactftool -n {n} -e {e} --uncipher {c}
```

## Hash Identification & Cracking
```bash
# Identify hash type
hashid '{hash}'
hash-identifier  # interactive

# John
john --wordlist=rockyou.txt hash.txt
john --format=raw-md5 --wordlist=rockyou.txt hash.txt

# Hashcat
hashcat -m 0 hash.txt rockyou.txt       # MD5
hashcat -m 100 hash.txt rockyou.txt     # SHA1
hashcat -m 1400 hash.txt rockyou.txt    # SHA256
```
