"""Generate a simple forensics test challenge for pipeline validation."""
import base64
import os
import struct
import zlib

FLAG = "flag{xiaokong_pipeline_works_2026}"

def create_png_with_hidden_flag(outpath):
    """Create a minimal valid PNG with flag hidden in tEXt chunk and trailing data."""
    # Minimal 4x4 red PNG
    width, height = 4, 4
    
    def make_chunk(chunk_type, data):
        raw = chunk_type + data
        return struct.pack(">I", len(data)) + raw + struct.pack(">I", zlib.crc32(raw) & 0xffffffff)
    
    # PNG signature
    sig = b'\x89PNG\r\n\x1a\n'
    
    # IHDR
    ihdr_data = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    ihdr = make_chunk(b'IHDR', ihdr_data)
    
    # IDAT (red pixels)
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'  # filter none
        for x in range(width):
            raw_data += b'\xff\x00\x00'  # RGB red
    idat_data = zlib.compress(raw_data)
    idat = make_chunk(b'IDAT', idat_data)
    
    # tEXt chunk with encoded flag (base64)
    encoded_flag = base64.b64encode(FLAG.encode()).decode()
    text_data = b'Comment\x00' + f'Check this: {encoded_flag}'.encode()
    text_chunk = make_chunk(b'tEXt', text_data)
    
    # IEND
    iend = make_chunk(b'IEND', b'')
    
    # Assemble PNG + append extra data after IEND
    png_data = sig + ihdr + text_chunk + idat + iend
    # Also hide flag in hex after PNG end (another layer)
    png_data += b'\n' + FLAG.encode().hex().encode()
    
    os.makedirs(os.path.dirname(outpath), exist_ok=True)
    with open(outpath, 'wb') as f:
        f.write(png_data)
    
    print(f"Challenge created: {outpath}")
    print(f"Size: {len(png_data)} bytes")
    print(f"Flag: {FLAG}")
    print(f"Hidden in: tEXt chunk (base64) + trailing hex data")

def create_challenge_description(outdir):
    """Create challenge metadata."""
    desc = f"""---
title: "Hidden Message"
category: stego
difficulty: easy
flag: "{FLAG}"
description: "A suspicious image was found on the suspect's computer. Find the hidden message."
---
# Challenge: Hidden Message

You are given an image file `evidence.png`. 
Find the hidden flag.

Hint: Look beyond what you see.
"""
    with open(os.path.join(outdir, "challenge.md"), 'w', encoding='utf-8') as f:
        f.write(desc)
    print(f"Description: {os.path.join(outdir, 'challenge.md')}")

if __name__ == "__main__":
    outdir = os.path.dirname(os.path.abspath(__file__))
    create_png_with_hidden_flag(os.path.join(outdir, "evidence.png"))
    create_challenge_description(outdir)
