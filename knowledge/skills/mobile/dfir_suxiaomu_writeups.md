# DFIR蘇小沐博客重点提炼（手机 / APK / 微信 / 汽车）

> 资料来源：
> - CSDN 主站：https://blog.csdn.net/NDASH（电子取证分类 https://blog.csdn.net/NDASH/category_9645483.html）
> - 博客园镜像：https://www.cnblogs.com/dfir/category/1890726.html
> - 取证站 dfirdd.com 当前 DNS 不通；shodan/CDN 有限可达。
>
> 本文只挑**手机/APK/微信**相关、且原 KB 没写或写得薄的点。Windows/视频图像/服务器/数据恢复条目按用户要求略过。

---

## 1. 已学条目一览（手机/APK 相关）

| 文章 | URL | 命中度 | 落点章节 |
| --- | --- | --- | --- |
| 【逆向分析篇】APK逆向脱壳过程（drizzleDumper） | https://blog.csdn.net/NDASH/article/details/135127086 | 高 | §2 |
| 【Android取证篇】渗透测试工具 apk2url | https://blog.csdn.net/NDASH/article/details/136572387 | 高 | §3 |
| 【微信取证篇】微信 Dat 文件加密原理和解密工具 | https://blog.csdn.net/NDASH/article/details/135815620 | 高 | §4 |
| 【微信取证篇】微信收藏图片存储记录 + 思维导图 | （多篇） | 中 | §4.4 |
| 【汽车取证篇】汽车取证 EDR 数据相关性判断 | https://blog.csdn.net/NDASH/article/details/135126741 | 中 | §5 |
| 【电子取证篇】汽车取证数据提取与汽车取证实例 | https://blog.csdn.net/NDASH/article/details/134813259 | 中 | §5 |
| iOS 17.3+ 失窃设备保护取证建议 | 主页一段 | 中 | §6 |

---

## 2. APK 脱壳：drizzleDumper 流程（**dexdump 类的经典老牌工具**）

> 与已有 KB（`android_packer_unpacker.md`）的 frida-dexdump / blackdex / FUPK 互补。drizzleDumper 是基于内存搜索 dex 头部的简易脱壳器，对**老版 360 加固/爱加密/梆梆免费版**有效，新加固几乎都失效——但赛场会出老题。

### 2.1 速查流程
```bash
# 1. 启动夜神模拟器，安装目标加固 APK
# 2. ADB 连模拟器
adb connect 127.0.0.1:62001                # 夜神
# adb connect 127.0.0.1:21503              # 雷电
# adb connect 127.0.0.1:7555               # MuMu

# 3. 推 drizzleDumper 到模拟器
adb push drizzleDumper /data/local/tmp/
adb shell chmod 0777 /data/local/tmp/drizzleDumper

# 4. 启动目标 App 后立即在 shell 执行
adb shell
cd /data/local/tmp
./drizzleDumper com.xzj.multiapps        # 包名

# 5. 工具会扫描进程内存找 dex 魔数 0x6465780A，dump 出 dex
# 6. 拉回 PC 用 jadx 反编
adb pull /data/local/tmp/com.xzj.multiapps_dumped_*.dex
jadx -d out com.xzj.multiapps_dumped_xx.dex
```

### 2.2 与现代脱壳工具对照
| 工具 | 适用加固 | 特点 |
| --- | --- | --- |
| **drizzleDumper** | 360 加固旧版、爱加密旧版、梆梆免费版 | 内存扫 dex 魔数；简单粗暴；ROOT 模拟器即可 |
| **frida-dexdump**（hluwa） | 多数主流加固（含较新的 360/爱加密/腾讯乐固） | frida 拦截系统加载点；命中率高；**赛场首选** |
| **blackdex** | 梆梆/360 加固新版（含 VMP）、阿里聚安全 | 直接安装 APK 形态运行；不需 root；适合非 root 真机 |
| **FUPK / FART** | 改 ROM 主动调用所有方法触发解密 | 整 dex 重组，最干净；需要刷定制 ROM |
| **DexKit** | 配合脱壳后定位关键类 | 不脱壳但帮你找到字段/方法 |
| **AppSpear / DroidUnpack** | 学术工具 | 论文级，工程使用少 |

> **回插到 `android_packer_unpacker.md`**：补充 drizzleDumper 一节作为"老题型兜底"。

### 2.3 APK 文件结构速记（蘇小沐版）
| 部分 | 含义 |
| --- | --- |
| `META-INF/` | 签名目录：MANIFEST.MF（每文件 SHA1 + Base64 摘要）/ CERT.SF（开发者私钥 SHA1-RSA 签名）/ CERT.RSA（公钥 + 算法） |
| `classes.dex` | dx 编译后的 Dalvik 字节码；多 dex（multidex） classes2.dex / classes3.dex |
| `res/` | 资源（图片/布局/动画） |
| `resources.arsc` | 编译后的二进制资源表（含 strings.xml 加密存储） |
| `lib/<abi>/` | so 库（arm64-v8a / armeabi-v7a / x86_64） |
| `assets/` | 原始资源（不参与 R 编译） |
| `AndroidManifest.xml` | AXML 二进制清单（包名/版本/权限/组件） |

> 这部分与 `apk_internals.md` §1–§3 重合，蘇小沐补充：**Android 权限四类**：normal / dangerous / signature / signature\|system；查壳推荐 **Apktool Box**（GUI）。

---

## 3. apk2url：APK 端点速提取（**取证赛 URL 一键题**）

### 3.1 工具原理
**apk2url**（github.com/n0mi1k/apk2url）= apktool + jadx + 正则筛 IP/URL。比手动 `strings | grep` 干净，比 APKleaks/MobSF/AppInfoScanner 提取率更高。

### 3.2 安装与使用
```bash
# 依赖
sudo apt install -y apktool jadx
# 下载
git clone https://github.com/n0mi1k/apk2url
cd apk2url && ./install.sh

# 使用
apk2url /path/to/app.apk
# 默认输出到 endpoints/ 目录：
#   _uniqurls.txt    # 唯一域名 + IP
#   _endpoints.txt   # 含完整路径的 URL
apk2url /path/to/app.apk log     # 加 log：记录端点出现的源文件路径
```

### 3.3 与已有方法的关系
| 找 URL 的方法 | 优劣 |
| --- | --- |
| `strings -el lib/**/*.so` + `grep http` | 快但混乱，含大量误报 |
| jadx 全局搜 `http://` `https://` | 仅 java 层，漏 native + assets |
| apktool d → grep -r http | 全面但慢 |
| **apk2url** | ★ 自动 apktool + jadx + 正则去重去噪 |
| **APKleaks** | 找密钥/token 强；URL 弱 |
| **MobSF** | 全面但部署重 |
| **AppInfoScanner** | 中文友好，结合静动态 |

**取证比赛速记**：
- 题目问"APK 上传地址 / 备用服务器 / API 域名"，**先 `apk2url` 一遍 → 看 `_uniqurls.txt`**；
- 没命中（被加密 / Base64 / Native）再回 jadx + frida。

> **回插到 `apk_crypto_analysis.md` §11.5.3**（URL 提取速查）+ `quick_reference.md`。

---

## 4. 微信图片 Dat 文件解密（**关键技术，跨手机/PC 通用**）

### 4.1 Dat 加密原理（**全字节单字节 XOR**）
```
Dat = 原图 ⊕ key   （key 是 1 字节，全文统一）
```
- key 与图片格式相关：JPG/PNG/GIF/BMP 文件头不同 → 推出不同 key；
- **同一台设备/同一账户内 key 是固定值**（不同账户 key 不同，不同设备 key 不同）；
- 解密**不需要 UIN / 微信 ID / SQLCipher 密码**——纯文件级。

### 4.2 解密推 key 步骤（**手算**）
```
1. 取 Dat 前 2 字节，例如：57 8E
2. 与已知图片头比对：
   JPG  FF D8 →  57⊕FF=A8, 8E⊕D8=56  → A8≠56 → ❌不一致
   PNG  89 50 →  57⊕89=DE, 8E⊕50=DE  → DE=DE → ✅命中，key=DE
   GIF  47 49 →  ...
   BMP  42 4D →  ...
3. 整文件 byte-wise XOR DE → 还原 PNG
```

### 4.3 一行 Python（**取证速记**）
```python
def decrypt_wx_dat(dat_path: str, out_path: str = None):
    """微信 Dat 文件解密：自动推 key + 还原原图"""
    SIGS = {b'\xff\xd8': '.jpg', b'\x89\x50': '.png', b'\x47\x49': '.gif', b'\x42\x4d': '.bmp'}
    data = open(dat_path, 'rb').read()
    for sig, ext in SIGS.items():
        k = data[0] ^ sig[0]
        if data[1] ^ sig[1] == k:                       # 两字节 key 一致
            out_path = out_path or dat_path + ext
            open(out_path, 'wb').write(bytes(b ^ k for b in data))
            print(f"OK key=0x{k:02x} -> {out_path}")
            return out_path
    print("NOT a wechat image dat")

# 批量
import glob, os
for p in glob.glob('**/*.dat', recursive=True):
    try: decrypt_wx_dat(p)
    except Exception as e: print(p, e)
```

> 现成工具：**WxDatViewer 2.5**（吾爱破解）、**wechat-dump**、**WeChat Image Decoder**。

### 4.4 PC 微信文件路径演进（**版本敏感**）
| 版本 | 图片 / 视频 / 文件路径 |
| --- | --- |
| **v3.7.0.26 之前** | `Documents\WeChat Files\<wxid>\FileStorage\{Image,Video,File}\` |
| **v3.7.0.26 ～ v3.9.9.35** | `Documents\WeChat Files\<wxid>\FileStorage\MsgAttach\<MD5(微信ID)>\{Image,Thumb}\` ← **图片按好友/群分桶** |
| **v3.9.9.35 之后** | 视频/文件回滚到旧位置；**图片仍在 MsgAttach 内** |
| **v4.x（QQ NT 风格新版）** | 整体重构为 `Tencent\xwechat_files\<wxid>\msg\attach\<hash>\...`；新版微信 sqlite 也变 |

**Android 微信图片对应路径**（不变，与 PC 完全独立）：
- `data/com.tencent.mm/MicroMsg/<32hex>/image2/<2hex>/<2hex>/<前缀>` → 同样是 Dat 异或加密
- `Android/data/com.tencent.mm/MicroMsg/<32hex>/image/...`（缓存）

**Mac 微信**：`~/Library/Containers/com.tencent.xinWeChat/Data/Library/Application Support/com.tencent.xinWeChat/<version>/<wxid>/Message/MessageTemp/`

### 4.5 微信收藏图片三处缓存（**蘇小沐发现**）
> 微信收藏夹的图片缓存有 **3 个并存位置**，名称都一样，有的明文有的加密，且**收藏的图片转发出去会被再次压缩**——大小不一致是出题点。

- `WeChat Files\<wxid>\Fav\xxxx\` 三套文件夹
- 部分明文 jpg / 部分 Dat 加密
- 取证比赛若问"原始收藏图 vs 转发图"——**用 SHA256 比对会发现**完全不同（重新压缩了）

### 4.6 与已有 `wechat_deep_dive.md` 关系
- 已有 KB 重在**聊天数据库（EnMicroMsg.db / MM.sqlite / Msg2.0.db）解密**；
- 蘇小沐重在**图片/视频文件级解密 + 路径演进**；
- 二者互补——本文 §4 直接回插到 `wechat_deep_dive.md` 新增"图片 Dat 解密"小节。

---

## 5. 汽车取证（EDR / TBOX / IVI / Android Auto）

### 5.1 EDR 是什么
- **EDR (Event Data Recorder)** = 事件数据记录器，俗称"汽车黑匣子"；
- 记录碰撞前后约 **5 秒**关键数据：
  - 车速 / 发动机转速 / 油门 / 刹车 / 安全带 / 气囊触发
  - 车辆 VIN / 时间戳 / 故障码（DTC）
- 取决于车型 + 制造商；中国 2022-01-01 起新车强制安装。

### 5.2 EDR 数据相关性陷阱（**蘇小沐重点**）
**典型反常**：
- 车速在 -2 到 -1.5s 区间骤减；
- 同期行车制动状态显示"关闭"。

**判读**：
1. **不是数据错误**——一般 EDR 提取要做两次比对；
2. **可能是自适应巡航控制（ACC）**主动减速 → 制动状态记录是"驾驶员脚踩刹车"，ACC 减速不记录；
3. **解释链**：导航/ACC 自动驾驶辅助导致的减速不会被传统"制动开关"记录，但能在 CAN 总线 / 雷达 / 摄像头数据里印证。

**取证原则**：
- **多数据关联分析**：EDR + IVI 行驶日志 + 车机黑匣子 + 嫌疑人手机 GPS + 监控视频；
- 不可孤证下结论。

### 5.3 汽车取证完整数据来源
| 来源 | 内容 |
| --- | --- |
| **EDR** | 碰撞前后 5s 关键参数 |
| **TBOX**（车联网终端） | 长期驾驶数据 + GPS 轨迹 + 远程数据上报 |
| **IVI**（车载信息娱乐） | 蓝牙配对、导航历史、媒体记录、通话、APP 安装（华为车机/鸿蒙座舱/特斯拉/蔚来 NOMI/理想 Mind） |
| **行车记录仪 / 360 影像** | 视频片段（FAT32/exFAT SD 卡） |
| **车钥匙 / 钥匙扣** | NFC / 433MHz 信号取证 |
| **充电桩日志**（电车） | 充电时间 / 位置 / 充电桩 ID |
| **OTA 升级日志** | 系统版本变更 |
| **嫌疑人手机蓝牙配对** | 与车机 MAC 配对历史（Android `bt_config.conf`） |
| **车机 App** | 蔚来 App / 理想 App / 特斯拉 App / 华为智行 / 高德地图 / 网易云听见 等 |

### 5.4 主流车机系统取证抓手（按品牌）
| 品牌/系统 | 操作系统 | 取证路径要点 |
| --- | --- | --- |
| **特斯拉** | Linux | gateway log + bo log + autopilot snapshot |
| **蔚来** | NIO OS（Android 派生） | 沙盒 + 高德/腾讯地图缓存 |
| **理想** | Li OS（Android） | Mind GPT 对话日志 + 行车视频 |
| **小鹏** | Xmart OS（Android） | 自研沙盒 + NGP 自动驾驶日志 |
| **华为问界 / 智界** | HarmonyOS（座舱） | DFX 日志 + HiCar |
| **比亚迪 DiLink** | Android 定制 | dlink_log/ + IVI sqlite |
| **大众/奔驰/宝马** | QNX / Linux | OEM 闭源；JTAG/eMMC 物理为主 |

### 5.5 与本仓的关系
- 已有 `dji_forensics.md` 处理无人机；
- 汽车专题应另立 `car_forensics.md`（待建）；
- 与 `bluetooth_forensics.md` 配合：手机蓝牙配对历史含车机名 → 推断车主关系。

---

## 6. iOS 17.3+ 失窃设备保护（**新功能 / 取证侧建议**）

### 6.1 功能背景
- iOS 17.3 引入 **Stolen Device Protection**；
- iOS 18.2 起**默认开启**；
- 启用条件：双重认证 + 启用定位 + 启用 Touch/Face ID。

### 6.2 行为
- **陌生地点修改关键设置**（Apple ID 密码、关闭"查找"、抹除等）需：
  - 生物识别认证（不接受设备密码兜底）；
  - **1 小时安全延迟**；
  - 第二次生物识别确认。
- 即使知道设备 PIN，也无法直接抹除/解绑。

### 6.3 取证侧建议
1. **现场关闭功能**：嫌疑人或合法持有人配合时，立即在"设置 → Face ID 与密码 → 失窃设备保护"关闭；
2. **现场即出文件系统镜像**：通过 Cellebrite Premium / Magnet AXIOM Inseyets / iLEAPP advanced logical 等，**绕过此机制走 trustcache**；
3. **法律调取**：联系 Apple 法务请求 iCloud 数据；
4. **设备物理保管**：Faraday 袋防止远程抹除。

> 回插到 `lock_password_forensics.md` 与 `ios_forensics.md` 越来越细化的"iOS 现代防护时间线"小节。

---

## 7. 蘇小沐通用方法论（散见多篇）

### 7.1 哈希校验值的"变与不变"
- **源盘 hash ≠ 镜像文件 hash**（取证常识但易混）：
  - 源盘 hash：原始物理盘 / 分区扇区流的 hash（含未分配空间）；
  - 镜像文件 hash：E01/DD 文件本身的 hash（含 ewf 元数据，所以 E01 不等于 DD）；
- 取证报告必须**两个都列出**。

### 7.2 WinHex 哈希大小写转换
- WinHex 默认输出大写；某些题目要小写：用 `(echo $hash).ToLower()` / `tr A-F a-f`。

### 7.3 GHO 系统镜像仿真
- 老 Ghost 镜像 `.gho`：用 **Ghost Explorer / EasyImageX** 解为 vmdk；
- 老 wim：`dism /Apply-Image /ImageFile:image.wim /ApplyDir:E:\` 应用到分区 → 仿真。
- 与 `emulator_forensics.md` 配合（已写）。

### 7.4 NTFS ADS 隐写
- 命令：`type secret.txt > normal.txt:hidden.txt`；
- 检测：`dir /R` / `Sysinternals streams.exe` / FTK Imager 看 `:` 后的流。
- 嫌疑人在 PC 隐藏小密码/密钥常用此法；与手机题里常见的"密码套娃"对应。

---

## 8. 与已有 KB 的回插

| 本文新增 | 已有 KB |
| --- | --- |
| §2 drizzleDumper | `android_packer_unpacker.md` 加一节 |
| §3 apk2url | `apk_crypto_analysis.md` §11.5.3 / `quick_reference.md` |
| §4 微信 Dat 异或解密 | `wechat_deep_dive.md` 新增"图片 Dat" |
| §4.4 PC 微信路径演进 | `wechat_deep_dive.md` 路径表 |
| §4.5 收藏图片三处缓存 | `wechat_deep_dive.md` |
| §5 汽车 EDR / IVI | 待建 `car_forensics.md` |
| §6 iOS 17.3+ Stolen Device Protection | `lock_password_forensics.md` / `ios_forensics.md` |
| §7.4 NTFS ADS | 跨方向，仅记 |

---

## 9. 暂未学到的蘇小沐文章（按计算机/服务器跳过）

- ESXi 镜像仿真 / GHO 仿真 / Autopsy 报告导出
- Windows 日志分析（Event log / 设备名称 / Windows 终端 ping）
- 阿里云 DNS 解析规则
- WinFR / WinHex 数据擦除
- 视频图像增强（去噪/色彩空间/车牌复原 / Impress 教程）—— 与手机/APK 关联弱
- 数据加解密 ADS 隐写 / FTK Imager DD-E01 仿真 / 鸿蒙 OS3 USB 调试位置 / 哈希基础

按用户聚焦"手机 / APK"原则，这些条目不展开。

---

## 10. 引用

- DFIR蘇小沐 CSDN 主页：https://blog.csdn.net/NDASH
- 电子取证分类：https://blog.csdn.net/NDASH/category_9645483.html
- 电子取证工具分类：https://blog.csdn.net/ndash/category_10621506.html
- 博客园：https://www.cnblogs.com/dfir
- 工具合集腾讯文档：https://docs.qq.com/sheet/DVXlYZkRB（蘇小沐维护）
