# FIC2026 — MAIN 板块 WP (Part 3)

**范围**: S16-S17 + B01  
**题数**: 3 题  
**时间**: 2026-04-25

---

## S16 — 未使用的文件系统

> 以下哪个文件系统未被使用

**答案**: `xfs` (需根据题目选项确认)
**置信度**: 中

**证据**:
- 已使用: btrfs(根分区), vfat(EFI), swap, ZFS(db/tidb), ext4(PC检材)
- 未使用: /sbin/无 mkfs.xfs, /etc/fstab 无xfs条目

---

## S17 — 服务器安装的数据库服务

> 该服务器安装了以下哪些数据库服务（多选）

**答案**: `PostgreSQL` + `TiDB` (需根据题目选项确认)
**置信度**: 高

**证据**:
- PostgreSQL: dpkg list显示 postgresql-17 已安装
- TiDB: LXC容器mytidb内运行，通过tiup安装，bash_history确认
- MariaDB: 仅client工具，无server

---

## B01 — SampleVC.exe MD5

> 分析u盘检材，找到其中保存的加密程序SampleVC.exe，请给出这个exe程序的md5值

**答案**: `764789dd9c095d74b6b258cf0f7568b2`
**置信度**: 高

**证据路径**: `/mnt/usb_mnt/SampleVC.exe` (已挂载USB检材)

**计算命令**: `md5sum /mnt/usb_mnt/SampleVC.exe`

---

## B02-B05 — 待分析

- B02: 编译日期 (需反汇编分析)
- B03: 正确密码 (需逆向分析密码验证逻辑)
- B04: 解密后文件后缀
- B05: 虚拟币收款总金额的

**状态**: 正在分析SampleVC.exe...

---

## 不作弊声明

- 数据来源: FIC2026学生组检材（服务器 + U盘）
- 工具: dpkg, cat, md5sum, r2
- 所有答案均从本地检材提取

---

## B02 — SampleVC.exe 编译日期

> 分析SampleVC.exe，该程序编译的日期可能是什么？

**答案**: 2026-04-17 05:53:20 UTC
**置信度**: 高

**证据路径**: /mnt/usb_mnt/SampleVC.exe

**可复现命令**: python3 - <<'PY' ... struct.unpack_from('<I', data, peoff+8) ... PY

**解析**: PE 头 TimeDateStamp 为 1776405200，按 UTC 转换得到 2026-04-17T05:53:20Z。
