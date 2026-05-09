# 检材1-计算机.E01 disk map

> 角色：computer_analyst
> 检材：`/mnt/d/2026FIC/检材1-计算机.E01` (22 GB EWF, 80 GB raw)
> 挂载方式：ewfmount → losetup -P → mount -o ro,noload
> 时间：2026-05-08 22:04 +08:00

## 1. EWF / loop / mount

```
/mnt/d/2026FIC/检材1-计算机.E01
  └─ ewfmount → /mnt/e01_pc/ewf1   (raw, 80 GB)
       └─ losetup -P → /dev/loop0
              ├─ /dev/loop0p1   (ext4)
              ├─ /dev/loop0p2   (no fs)
              ├─ /dev/loop0p3   (ext4)
              ├─ /dev/loop0p4   (扩展分区)
              └─ /dev/loop0p5   (ext4)
```

## 2. 分区表 (mmls)

DOS partition table, 512-byte sectors, root device 80 GB

| Slot | Start sector | Length sector | Length GB | Label | Type | Mount |
|---|---|---|---|---|---|---|
| p1 | 2048 | 3,145,728 | 1.5 | `Boot` | ext4 | `/mnt/pc_boot` |
| p2 | 3,147,776 | 16,519,168 | 8.0 | (none) | — | (skipped, 无 fs) |
| p3 | 19,666,944 | 114,552,832 | 54.6 | `Roota` | ext4 | **`/mnt/pc_root`** |
| p4 (Win95 Ext) | 134,219,776 | 33,552,384 | 16.0 | — | — | (扩展) |
| p5 | 134,219,784 | 33,552,376 | 16.0 | `_dde_data` | ext4 | **`/mnt/pc_data`** |

UUIDs:

- p1 `Boot`: `5335406f-943d-4a5d-a8f6-fe41030c2bf4`
- p3 `Roota`: `2f13d488-5d17-4f9b-aff8-9cb85c802bea`
- p5 `_dde_data`: `0d46c1f7-7deb-4f86-9637-745eaf7295a5`
- DOS PARTUUID 前缀: `4a78e5e8`

## 3. Deepin 23.1 拓扑特征

- **A/B 双系统镜像**：仅 `Roota` 存在（`Rootb` 缺，未做过 OS 升级）
- **数据/系统分离**：rootfs 上的 `/home/lha` 实际是空骨架，真实数据在 `/mnt/data/home/lha`（即 p5 `_dde_data`）
- **OSTree-like 不可变 rootfs**：用户写不到 `/usr`、`/etc` 由 etcmerged 托管

## 4. 各题预期取证位置

| 题 | 预期分区 | 主要路径 |
|---|---|---|
| Q4 apk 下载链接（推广图）| p5 `_dde_data` | `~/Pictures/`, `~/Documents/`, `~/Desktop/`，可能 `~/.config/Foxmail/` 邮件附件 |
| Q6 AI 软件模型 | p5 `_dde_data` | `~/.config/<AI软件>/` 配置 json |
| Q7 AI apiKey | p5 `_dde_data` | 同 Q6，配置或 sqlite |
| Q8 勒索联系方式 | p5 `_dde_data` | `~/Desktop/` 勒索信、`~/.config/google-chrome/` 历史、邮件 |
| Q9/Q10 保险柜 | binary 角色 vc 解出后 | （依赖外部）|

## 5. 注意事项

- mount 加 `ro,noload` 避免 ext4 journal replay 改镜像
- 中文路径在 WSL 里通过 PowerShell 传参时易触发 quoting 雷，建议放 .sh 文件中执行
- 后续脚本一律走 `/mnt/f/cloud/DD/.tmp_*.sh`（本仓 .gitignore 后续可加）
