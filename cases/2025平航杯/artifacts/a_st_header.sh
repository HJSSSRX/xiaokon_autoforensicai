#!/bin/bash
python3 << 'PYEOF'
import struct, json, zipfile
zf = zipfile.ZipFile('/mnt/win_c/Users/起早王/Downloads/crack.zip')

for name in ['crack/model.safetensors', 'crack/story/model.safetensors']:
    with zf.open(name) as f:
        data = f.read(300000)
    n = struct.unpack('<Q', data[:8])[0]
    print('===', name, ' header_len=', n)
    try:
        j = json.loads(data[8:8+n].decode('utf-8'))
        md = j.get('__metadata__', {})
        print('metadata:', json.dumps(md, ensure_ascii=False))
        print('keys count:', len([k for k in j if k != '__metadata__']))
        print('first 5:', list(j.keys())[:5])
        print('last 5:', list(j.keys())[-5:])
    except Exception as e:
        print('err', e)

# pytorch bin (zip-like, pickle inside)
print()
print('=== story/pytorch_model.bin ===')
with zf.open('crack/story/pytorch_model.bin') as f:
    head = f.read(8000)
print('head bytes:', head[:200])
import io
try:
    inner = zipfile.ZipFile(io.BytesIO(head + b'\x00'*100))
    print('zip files:', inner.namelist()[:20])
except Exception as e:
    print('not zipfile or trunc', e)
PYEOF