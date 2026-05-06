---
tags: [mobile_forensics, android, emulator, nox, apk_analysis, exe_analysis, ransomware, reverse_engineering]
tools: [火眼, Detect_It_Easy, IDA, jadx, DB_Browser, 雷电模拟器]
category: mobile_forensics
difficulty: hard
source: 2022_changancup
date: 2026-05-05
verified: true
---
# Title: 2022长安杯 — 安卓模拟器 & EXE/APK 逆向（检材4）

## Problem
分析幕后老板使用的安卓模拟器镜像，提取通讯记录、VPN配置、录屏数据。逆向分析勒索加密程序和恶意APK。

## Solution Steps

### 安卓模拟器取证

1. 识别模拟器类型
   → 搜索 `.npbk` 文件 → 夜神模拟器(Nox)

2. 提取阿里云账号
   → 火眼分析直接获取

3. 提取 VPN 配置
   → 火眼分析获取 VPN 软件名称和节点 IP

4. 查找录屏软件安装时间
   → 通过 APK 包名找到安装信息
   → 安装时间在 packages.xml 或类似记录中

5. 关联录屏文件原始名称
   → 数据库位置: `Nox_2-disk2.vmdk/分区4/data/com.jiadi.luping/databases/record.db`
   → 用 DB Browser 打开分析

6. 获取录屏软件登录手机号
   → 同时导出 `record.db` 和 `record.db-wal` (WAL日志)
   → DB Browser 中查看

7. 提取勒索邮箱地址
   → 火眼直接分析: `skterran@163.com`

### EXE 逆向分析

8. 识别编程语言
   - 方法1: Detect It Easy 直接识别 → Python
   - 方法2: IDA 分析发现 Python 特征

9. 分析加密文件类型和算法
   → 反编译 Python EXE 获取源代码
   → 查看加密文件扩展名列表和加密算法

### APK 逆向分析

10. 获取 APK 包名
    → 雷电模拟器直接获取

11. 查看 APK 权限
    → `AndroidManifest.xml` 中查看

12. APK 脱壳后反编译
    → 搜索 FLAG 关键字获取 FLAG2

13. FLAG3 逆向
    - 分析 Java 代码: `equals` 比较输入值与 `OooO0oo`
    - `OooO0oo` = `decrypt(hex_to_bytes("ffd4d7459ad24cd035611b014a2cccac"))`
    - `decrypt` 是 native 方法，在 `libcipher.so` 中
    - 解法: 写 Android 工程调用 so 库中的 decrypt 函数
    ```java
    String out = new String(new App().decrypt(
        OooO0O0("ffd4d7459ad24cd035611b014a2cccac")));
    ```
    → 推送到模拟器执行，查看 logcat 输出

## Key Takeaways
- 夜神模拟器备份文件扩展名为 `.npbk`
- 安卓模拟器的虚拟磁盘(vmdk)可直接挂载分析
- SQLite 的 WAL 日志文件 (`-wal`) 包含未写入主数据库的最新数据，必须一起导出
- Python 打包的 EXE 可用 pyinstxtractor + uncompyle6 反编译
- APK 逆向: 先脱壳 → jadx 反编译 → 分析加密逻辑 → 必要时调用 native so
- native so 中的函数可通过编写 Android 工程直接调用执行
