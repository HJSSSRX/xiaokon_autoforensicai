---
tags: [training_validation, computer_forensics, steganography, password_cracking, stable_diffusion, mobaxterm, qtscrcpy]
tools: [e01_reader, dissect, exiftool, msoffcrypto, xlrd, python]
category: training_validation
difficulty: medium
source: 2024FIC_finals
date: 2026-05-06
verified: true
---

# 2024FIC Finals — Training Mode Validation Report

## Summary

**Mode**: Full-Auto Training (独立解题，不参考 WP)
**Image**: `E:\ffffff-JIANCAI\2024FIC决赛\PersonalPC.E01` (60GB, NTFS)
**Tool**: `e01_reader.py` + dissect library (Python 3.10)
**Scope**: Computer Forensics (15 questions), CLI-solvable subset

## Independently Verified Answers

| Q# | Question | AI Independent Answer | KB Answer | Match |
|----|----------|----------------------|-----------|-------|
| Q2 | 备忘录.txt SHA1 | fded9342533d92fa46fc4aabd113765a7a352ceb | fded9342533d92fa46fc4aabd113765a7a352ceb | ✅ |
| Q3 | SSH tool name | MobaXterm | MobaXterm | ✅ |
| Q4 | SSH "node" port | 122 | 122 | ✅ |
| Q5 | MobaXterm master password hint | mobapass00 (from 备忘录) | mobapass00 | ✅ |
| Q6 | QtScrcpy VM count | 3 VMs (15 ports, 3 groups) | 3 | ✅ |
| Q8 | Hidden file in 老婆.png | OLE2 XLS, 24576 bytes after IEND | XLS hidden after PNG EOF | ✅ |
| Q9 | XLS password / 日报 password | P1ssw0rd (xls) / P1ssw1rd (docx) | P1ssw0rd / P1ssw1rd | ✅ |
| Q10 | AI image generation tool | stable-diffusion-webui | stable-diffusion-webui | ✅ |
| Q11 | SD webui port | 7860 | 7860 | ✅ |
| Q12 | AI-generated image count | 41 (in txt2img-images/2024-03-13/) | 41 | ✅ |
| Q14 | Burning car prompt keywords | ABD (china, high way, car on fire) | ABD | ✅ |
| Q15 | 老婆.png generation seed | 3719279995 | 3719279995 | ✅ |

**Score: 12/15 independently verified** (80%)

## Not Independently Verified

| Q# | Reason |
|----|--------|
| Q1 | Source disk SHA256 requires reading full 60GB stream (feasible but very slow) |
| Q7 | 老婆.png is 1,456,134 bytes but Q7 asks specific hash which needs Q clarification |
| Q13 | Model file SHA256 requires extracting ~2GB safetensors file (feasible but very slow) |

## Key Findings (Independent Discovery)

### 备忘录.txt (from Recycle Bin)
- Original path: `C:\Users\Luck\Desktop\备忘录.txt`
- Contains password hints: mobapass00, xls/docx password pattern
- "日报的密码和老婆的密码只修改了数字部分"

### MobaXterm Configuration
- Path: `/Program Files/MobaXterm/MobaXterm.ini`
- 4 SSH sessions: root@192.168.71.100, node(droid)@192.168.71.100, root@192.168.71.137, node(droid)@192.168.71.137
- "node" sessions use port 122, "root" sessions use port 22
- Encrypted passwords stored in [Passwords] section

### QtScrcpy Configuration
- Path: `/Users/Luck/Documents/QtScrcpy-win-x64-v2.2.0/config/userdata.ini`
- 15 port configurations for IP 192.168.71.100
- Pattern: 3 groups (1xxxx, 2xxxx, 3xxxx) × 5 ports each → 3 VMs

### Steganography in 老婆.png
- OLE2 (XLS) data appended after PNG IEND marker
- 24,576 bytes of hidden data
- Contains 50 citizen records (phone + name)
- XLS encrypted with password: P1ssw0rd

### Stable Diffusion Artifacts
- Install path: `/Users/Luck/AppData/Local/stable-diffusion-webui/`
- Models: againmix_v20.safetensors, v1-5-pruned-emaonly.safetensors
- 41 generated images in output/txt2img-images/2024-03-13/
- 老婆.png metadata: Model=againmix_v20, Seed=3719279995, Steps=20
- Burning car (00036): Model=v1-5-pruned-emaonly, prompts include "china, high way, car on fire"

## Conclusion

Training mode is now functional. The e01_reader.py tool + dissect library enables:
1. **Filesystem browsing** — ls, search across NTFS partitions
2. **File extraction** — extract any file from E01
3. **Content analysis** — cat, hash for files inside E01
4. **Steganography** — Python-based PNG EOF analysis
5. **Password cracking** — msoffcrypto brute-force with hint-based wordlists
6. **Metadata extraction** — exiftool for EXIF/SD parameters

### Remaining Gaps
- Large file operations (60GB hash, 2GB model extraction) — feasible but slow
- GUI-only tasks (PVE web UI, MobaXterm GUI) — still require human
- Nested VM operations — still require human
