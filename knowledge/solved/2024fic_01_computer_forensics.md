---
tags: [computer_forensics, windows, hash, recycle_bin, ssh, mobaxterm, qtscrcpy, steganography, png_hidden_data, password_cracking, stable_diffusion, ai_image, exif, prompt_extraction]
tools: [sha256sum, sha1sum, hashcat, foremost, everything, mobaxterm, qtscrcpy, stable_diffusion]
category: computer_forensics
difficulty: medium
source: 2024FIC_finals
date: 2026-05-05
verified: partial_12_of_15
---
# Title: 2024FIC Finals - Computer Forensics (15 Questions)

## Problem
Given a Windows personal computer image (PersonalPC.E01, ~32GB), answer 15 questions about the suspect's activities including hash values, SSH connections, AI image generation, steganography, and password cracking.

## Evidence
- PersonalPC.E01 (~32GB) ‚Ä?Windows personal computer disk image

## Solution Steps

### Q1: Calculate the original evidence SHA256 value
Calculate the **source disk** SHA256 (not the E01 image hash):
```
SHA256 of source disk = 484117F3002E5B876C81DD786F899A439514BB0621D62D58F731E5B344DB3634
```
‚Ü?**484117F3002E5B876C81DD786F899A439514BB0621D62D58F731E5B344DB3634**

### Q2: Recycle Bin "Â§áÂøòÂΩ?txt" SHA1 value
Find the file in Recycle Bin records (basic info section in forensic tool), restore it, then hash:
```
SHA1 = fded9342533d92fa46fc4aabd113765a7a352ceb
```
‚Ü?**fded9342533d92fa46fc4aabd113765a7a352ceb**

### Q3: SSH tool name
The SSH tool is visible in analysis ‚Ä?MobaXterm (sessions are also recorded).
‚Ü?**MobaXterm**

### Q4: SSH "node" connection port
Open MobaXterm (password from Â§áÂøòÂΩ? `mobapass00`), right-click "node" ‚Ü?view settings.
‚Ü?**122**

### Q5: Number of Android VMs connected at 2024-03-12 17:13
Search files around timestamp 2024-03-12 17:12~17:14, find a screenshot showing phone control interface with 5 android VMs.
‚Ü?**5**

### Q6: QtScrcpy configured Android VMs (by port count)
Use Everything to search for QtScrcpy config. Check `userdata.ini` in config directory. Ports: 21111, 22222, 23333... totaling 15 entries.
‚Ü?**15**

### Q7: Desktop "ËÄÅÂ©Ü.png" SHA256
Extract from desktop and calculate:
```
SHA256 = 02139BF305630CEFFADD6926C202BAE655C79D25A64F5C7A1C62BC4C91C9CCF1
```
‚Ü?**02139BF305630CEFFADD6926C202BAE655C79D25A64F5C7A1C62BC4C91C9CCF1**

### Q8: Hidden XLS password in ËÄÅÂ©Ü.png
PNG has XLS data appended after PNG EOF marker (AE426082). Extract with Foremost.
Password hint from Â§áÂøòÂΩ? 8 chars, upper+lower+digits, ends with "rd".
```
hashcat mask attack: ?1?1?1?1?1?1rd (where ?1 = ?u?l?d)
```
‚Ü?Password: **P1ssw0rd**

### Q9: Desktop docx "2024Âπ?Êú?3Êó•ÊòüÊúü‰∏â Êó•Êä•.docx" password
Â§áÂøòÂΩ?says: same as ËÄÅÂ©Ü's password, only change the digit part.
```
hashcat mask: P1ssw?1rd (where ?1 = ?u?l?d)
```
‚Ü?Password: **P1ssw1rd**
Content: AI image generation notes with screenshots.

### Q10: AI software name
From docx screenshots, top-left corner shows "Stable Diffusion". Search confirms installation.
‚Ü?**stable-diffusion-webui**

### Q11: AI software listening port
Check browser history for "stable diffusion" keyword.
‚Ü?**7860**

### Q12: AI-generated images in "2024-03-13" directory
Use Everything to find 2024-03-13 folders under stable-diffusion install path. One folder has 41 AI-generated images (6 fingers visible). Another folder has puzzles (not AI-generated).
‚Ü?**41**

### Q13: Model SHA256 for burning car image
The docx mentions model: `v1-5-pruned-emaonly.safetensors`. Search and hash:
```
SHA256 = 22E8515AA5985B776AFC1E48647F23F5651A317D2497A91232D03A1C4FEEAE2C
```
‚Ü?**22E8515AA5985B776AFC1E48647F23F5651A317D2497A91232D03A1C4FEEAE2C**

### Q14: Positive prompts for burning car image (00036-957419862.png)
Options: A.china B.high way C.fast speed D.car on fire E.no people
Check IHDR block of the PNG (or EXIF of corresponding JPG) for embedded prompt metadata.
‚Ü?**ABD** (china, high way, car on fire)

### Q15: Image generation seed of ËÄÅÂ©Ü.png
Check IHDR block of ËÄÅÂ©Ü.png for Stable Diffusion metadata.
‚Ü?**3719279995**

## Key Takeaways
- **Â§áÂøòÂΩ?in Recycle Bin is critical**: Contains MobaXterm password (mobapass00), password hints for xls/docx
- **PNG steganography**: Data appended after PNG EOF marker ‚Ä?use hex editor to find AE426082, then Foremost to extract
- **Password cracking strategy**: Use hints from Â§áÂøòÂΩ?to build targeted masks, dramatically reducing search space
- **Stable Diffusion metadata**: Generation parameters (prompt, seed, model) are embedded in PNG IHDR blocks and JPG EXIF
- **Everything search**: Essential for locating files in large forensic images quickly
- **QtScrcpy config**: `userdata.ini` stores VM port configurations
- **MobaXterm**: Stores SSH session configs; may require master password to view saved credentials

## Answer
Q1: 484117F3002E5B876C81DD786F899A439514BB0621D62D58F731E5B344DB3634
Q2: fded9342533d92fa46fc4aabd113765a7a352ceb
Q3: MobaXterm
Q4: 122
Q5: 5
Q6: 15
Q7: 02139BF305630CEFFADD6926C202BAE655C79D25A64F5C7A1C62BC4C91C9CCF1
Q8: P1ssw0rd
Q9: P1ssw1rd
Q10: stable-diffusion-webui
Q11: 7860
Q12: 41
Q13: 22E8515AA5985B776AFC1E48647F23F5651A317D2497A91232D03A1C4FEEAE2C
Q14: ABD
Q15: 3719279995
