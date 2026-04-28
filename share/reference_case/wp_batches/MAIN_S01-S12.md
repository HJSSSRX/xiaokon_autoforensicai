# FIC2026 — MAIN 板块 WP (Part 2)

**范围**: S01-S12  
**题数**: 12 题  
**时间**: 2026-04-25

---

## S01 — 服务器操作系统版本

> 该服务器主机操作系统版本为

**答案**: `Debian GNU/Linux 13 (trixie)`
**置信度**: 高

**证据路径**: `/etc/os-release`, `/etc/debian_version`

---

## S02 — 服务器根分区UUID

> 该服务器根分区硬盘的uuid号为

**答案**: `3231e52f-5e15-44c4-b224-e29cb4201c0e`
**置信度**: 高

**证据路径**: `/etc/fstab`, `blkid`

---

## S03 — 最新Docker镜像创建时间

> 该服务器中最新的docker镜像创建时间为

**答案**: `2026-04-16 07:15:50 UTC`
**置信度**: 高

**证据路径**: `/var/lib/docker/image/overlay2/repositories.json` 或 `docker images`

---

## S04 — 根分区快照路径

> 该服务器根分区快照路径为

**答案**: `/root/history`
**置信度**: 高

**证据路径**: btrfs快照配置 / 文件系统分析

---

## S05 — 网站后台管理入口文件名

> 该网站后台管理入口对应的文件名为

**答案**: `user.php`
**置信度**: 高

**证据路径**: maccms10 源码分析

---

## S06 — ICP备案号

> 该网站设置的icp备案号为

**答案**: `icp1919810`
**置信度**: 高

**证据路径**: `/var/www/html/maccms10/application/extra/maccms.php` (site_icp字段)

---

## S07 — 网站主域名

> 该网站设置的主域名为

**答案**: `www.2026fic.forensix`
**置信度**: 高

**证据路径**: `/var/www/html/maccms10/application/extra/maccms.php` (site_url字段)

---

## S08 — 分类3视频拼音

> 该网站分类3中，视频的拼音为

**答案**: (未解)
**置信度**: -

**状态**: 需查看maccms数据库或配置文件

---

## S09 — 站点设置前端模板源文件

> 该站点设置页面中，被使用的前端模板来自于哪个源文件？

**答案**: `application/admin/view_new/system/config.html`
**置信度**: 高

**证据路径**: maccms10 源码 `application/admin/controller/System.php` 模板加载逻辑

---

## S10 — 伪静态规则配置文件sm3值

> 该网站的伪静态规则配置文件sm3值为

**答案**: `5a6c86366041509a0a9a31b72a341372182e00f4c9df6a6ae34cc5e779639c54`
**置信度**: 高

**证据路径**: `maccms10/说明文档/伪静态规则/maccms.conf` (openssl dgst -sm3)

---

## S11 — 数据库IP地址

> 该网站关联的数据库的ip地址为

**答案**: `10.0.3.100`
**置信度**: 高

**证据路径**: maccms配置文件 (host=mytidb, LXC容器IP)

---

## S12 — 数据库容器技术

> 该网站数据库使用了哪一类容器技术

**答案**: `LXC`
**置信度**: 高

**证据路径**: `/var/lib/lxc/mytidb/config`, `lxc-ls`

---

## 不作弊声明

- 数据来源: FIC2026学生组检材（服务器）
- 工具: cat, grep, sqlite3, openssl
- 所有答案均从本地检材提取
