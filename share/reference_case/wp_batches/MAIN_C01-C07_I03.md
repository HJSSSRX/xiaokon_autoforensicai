# FIC2026 — MAIN 板块 WP (Part 1)

**范围**: C01-C07 + I03  
**题数**: 8 题  
**时间**: 2026-04-25

---

## C01 — 操作系统版本号

> 分析计算机检材，操作系统版本号为

**答案**: `UnionTech OS Desktop 20 Pro` (或 `Debian 10` 底层)
**置信度**: 高

**证据路径**: `/etc/os-release`, `/etc/deepin-version`

---

## C02 — 钓鱼邮件发件人

> 分析计算机检材，李安弘曾收到一份免费领取token的邮件的疑似钓鱼邮件，其发送用户邮箱为

**答案**: `hf13338261292@outlook.com`
**置信度**: 高

**证据路径**: deepin-mail LevelDB 数据 / Foxmail 缓存

---

## C03 — 黄金换现金商家联系方式

> 分析计算机检材，李安弘电脑中记录的黄金换现金的商家联系方式为

**答案**: (未解)
**置信度**: -

**状态**: 仍在搜索邮件内容和用户文档

---

## C04 — 推广设计图APK下载链接

> 分析计算机检材，推广设计图中的apk下载链接为

**答案**: (未解)
**置信度**: -

**状态**: OCR识别效果差，需人工查看或更精确搜索

---

## C05 — VPN代理端口

> 分析计算机检材，李安弘电脑vpn软件开放的代理端口为

**答案**: `7897`
**置信度**: 高

**证据路径**: `/root/.config/clash-verge/verge.yaml` (mixed-port: 7897)

---

## C06 — AI软件模型类型

> 分析计算机检材，李安弘电脑中AI软件当前使用的模型类型为

**答案**: `DeepSeek`
**置信度**: 高

**证据路径**: `/root/.local/share/deepin/uos-ai-assistant/db/basic` (llm表 name字段)

---

## C07 — AI软件apiKey

> 分析计算机检材，李安弘电脑中AI软件当前使用的模型apiKey为

**答案**: `RFTYsCjYh/0F+p2gvEgpKtCQYHue1YQtOEU1GFS/I1Pu0HYpIWAvz/C2dNvxXi0FXPvMYE23hTewirnq1u63yg==`
**置信度**: 高

**证据路径**: `/root/.local/share/deepin/uos-ai-assistant/db/basic` (llm表 account_proxy字段，JSON格式，AES加密存储)

---

## I03 — ngrok提供的域名

> ngrok提供的域名为

**答案**: `blemish-junior-unengaged.ngrok-free.dev`
**置信度**: 高

**证据路径**: nginx访问日志 / maccms配置

---

## 不作弊声明

- 数据来源: FIC2026学生组检材（PC/服务器）
- 工具: sqlite3, strings, grep, r2, Python
- 所有答案均从本地检材提取，未访问外部网络资源
