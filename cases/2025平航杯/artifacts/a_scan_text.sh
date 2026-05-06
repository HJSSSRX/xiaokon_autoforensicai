#!/bin/bash
python3 << 'PYEOF'
import zipfile, json, re

zf = zipfile.ZipFile('/mnt/win_c/Users/起早王/Downloads/crack.zip')
print('=== Files in zip ===')
for n in zf.namelist():
    info = zf.getinfo(n)
    print(f'{info.file_size:>12} {n}')

print()
print('=== tokenizer.json scan for flag ===')
for name in ['crack/tokenizer.json', 'crack/vocab.json', 'crack/merges.txt',
             'crack/story/tokenizer.json', 'crack/story/vocab.json']:
    try:
        with zf.open(name) as f:
            data = f.read().decode('utf-8','replace')
        hits = re.findall(r'flag\d?\{[^"\\}]{1,200}\}', data, re.IGNORECASE)
        if hits:
            print(f'{name}: HIT {hits[:5]}')
        else:
            print(f'{name}: no flag pattern, size={len(data)}')
    except KeyError:
        pass

print()
print('=== generation_config + configuration ===')
for n in ['crack/configuration.json','crack/generation_config.json','crack/story/special_tokens_map.json','crack/story/tokenizer_config.json','crack/story/config.json']:
    try:
        print('##', n)
        print(zf.read(n).decode())
    except: pass

print()
print('=== ico/png files for steganography candidates ===')
for n in ['crack/cat.png','crack/user.png','crack/cat_icon.ico']:
    info = zf.getinfo(n)
    print(n, 'size=', info.file_size)
PYEOF