# 微信取证深度方法论

> 适用：Android/iOS/PC 微信全场景取证。题目特征：见到 `EnMicroMsg.db`、`MicroMsg.db`、`wxid_xxx`、`uin`、`MMSetting.archive`、`FTS5IndexMicroMsg`、`emoji`/`image2`/`voice2`/`video`、`SnsMicroMsg`、`WCDB`、`MM.sqlite`、`Msg_*.db`、`Wallet_data.bin`、`AccountId`、`KeyValueDB` 等。

---

## 1. 取证总策略（按平台分流）

| 平台 | 关键路径 | 加密 | 关键密钥 |
| --- | --- | --- | --- |
| **Android（旧版 6.7 之前）** | `/data/data/com.tencent.mm/MicroMsg/<MD5(mm+uin)>/EnMicroMsg.db` | SQLCipher v1，AES-256-CBC | **MD5(IMEI+uin) 前 7 位** |
| **Android（新版 7.0+）** | `/data/data/com.tencent.mm/MicroMsg/<MD5>/EnMicroMsg.db` 或 `MSG0.db` `MSG1.db`（WCDB） | WCDB（SQLCipher 变体），key 衍生改变 | 新版部分用 `MD5(IMEI+uin)`，部分加随机盐，需逆向当版 |
| **iOS** | `AppDomain-com.tencent.xin/Documents/<MD5(wxid)>/DB/MM.sqlite` | iOS 8+ **未加密**（或 WCDB 弱加密，多数无密码） | 一般直接打开 |
| **PC（Windows）** | `%USERPROFILE%\Documents\WeChat Files\<wxid>\Msg\*.db` | SQLCipher，key=64 字节十六进制 | 内存读取 `WeChatWin.dll`，工具：PyWxDump/WechatExporter |
| **PC（Mac）** | `~/Library/Containers/com.tencent.xinWeChat/.../Message/*.db` | 同上 | 同上 |

---

## 2. Android 微信解密（旧版核心）

### 2.1 求 IMEI / uin
- **IMEI**（注意：Android 10+ 应用拿不到 IMEI 时，微信会用 `1234567890ABCDEF` 这个**默认值** → 只要 SDK ≥ 29 一律先试默认值）。
  - 提取顺序：`getprop ro.boot.imei` / `dumpsys iphonesubinfo` / 对话框 `*#06#` / 手机自检；BFU 状态用 efs 分区。
- **uin**：用户在当前手机的登录 ID（int 32 位整数，**有符号**）。
  - 来源：`shared_prefs/auth_info_key_prefs.xml` → `_auth_uin`
  - 或 `shared_prefs/system_config_prefs.xml` → `default_uin`
  - 或 `MicroMsg/CompatibleInfo.cfg`（plist/SerializedObject）
  - 多账号情况下 `MicroMsg/<MD5>/` 子目录名就是 `MD5("mm"+uin)`，反推：枚举 uin 算 MD5 比对目录名。

### 2.2 计算密钥
```python
import hashlib
imei = "1234567890ABCDEF"   # 或真实 IMEI
uin  = "1234567890"         # 字符串形式（含符号位的十进制）
key  = hashlib.md5((imei+uin).encode()).hexdigest()[:7]   # 7 字符
print(key)
```
- **常见坑**：
  - uin 是负数时要带负号字符串，例如 `-1234567890`。
  - IMEI 默认值就是字面量 `1234567890ABCDEF`，全大写。
  - 国行小米/华为部分版本 IMEI 取不到时用 `androidid` 或 `serialno`，看 App 当版逻辑。

### 2.3 解密
```bash
# pysqlcipher3 / sqlcipher CLI
sqlcipher EnMicroMsg.db
sqlite> PRAGMA key='abc1234';      -- 7 位 key
sqlite> PRAGMA cipher_use_hmac=OFF;
sqlite> PRAGMA cipher_page_size=1024;
sqlite> PRAGMA kdf_iter=4000;
sqlite> PRAGMA cipher_hmac_algorithm=HMAC_SHA1;
sqlite> PRAGMA cipher_kdf_algorithm=PBKDF2_HMAC_SHA1;
sqlite> ATTACH DATABASE 'plain.db' AS plaintext KEY '';
sqlite> SELECT sqlcipher_export('plaintext');
sqlite> DETACH DATABASE plaintext;
```
- 若 `PRAGMA key` 后立即 `.tables` 报 `file is not a database`，说明 key 错或参数（cipher_use_hmac/cipher_page_size/kdf_iter）错；旧版微信关键参数就是 **HMAC=OFF + page=1024 + kdf=4000**。
- 一键工具：[wechat-decipher-android / wxBackupDecrypt](https://github.com/) 等。

### 2.4 关键表
| 表 | 用途 |
| --- | --- |
| `message` | 全量消息（type=1 文字、3 图片、34 语音、43 视频、47 表情、49 链接/转账/红包、10000 系统） |
| `rcontact` | 联系人（含群） |
| `chatroom` | 群基本信息 |
| `userinfo` | 当前账号 |
| `ImgInfo2` | 图片缩略图与原图映射（`bigImgPath` 是真正图片名） |
| `EmojiInfo` | 表情包 |
| `WeixinFriend` | 朋友关系（部分版本无） |
| `SnsInfo`（SnsMicroMsg.db） | 朋友圈 |
| `SnsComment` | 朋友圈评论 |

```sql
-- 聊天记录（按好友/群展开）
SELECT datetime(createTime/1000,'unixepoch','localtime') AS t,
       talker, isSend, type, content, imgPath
FROM message ORDER BY createTime;

-- 联系人
SELECT username, nickname, conRemark, type FROM rcontact;
```

### 2.5 媒体文件
- 图片：`MicroMsg/<MD5>/image2/xx/yy/<hash>.jpg`（前两位 + 后两位作子目录），`message.imgPath` 即文件名（不含扩展）。
- 语音：`voice2/xx/yy/msg_<msgSvrId>.amr`（amr/silk-v3，PC 端常需 silk → wav）。
- 视频：`video/<msgSvrId>.mp4` + `.mp4_thumb`。
- 文件：`Download/`、`OpenApi/`、`Files/`。
- 表情：`emoji/`、`emoji_dict/`。

```bash
# silk 转 wav
git clone https://github.com/kn007/silk-v3-decoder
./silk-v3-decoder/converter.sh input.amr wav
```

### 2.6 EnMicroMsg 删除消息恢复
- WCDB 用 SQLite 底层，`message` 表删除后行进入 free page；用 `undark` / 自写脚本扫 page 找匹配模式（`createTime` 是 13 位毫秒时间戳，`talker` 必含 `@chatroom` 或 `wxid_`）。
- 建议先 `sqlcipher_export` 解密落地为明文，再用 SQLite 恢复工具。

---

## 3. iOS 微信解析

### 3.1 路径
```
HomeDomain → /Documents/   (在 iOS 备份里映射 AppDomain-com.tencent.xin)
AppDomain-com.tencent.xin/Documents/<MD5(wxid)>/DB/MM.sqlite       # 主消息库
AppDomain-com.tencent.xin/Documents/<MD5(wxid)>/DB/WCDB_Contact.sqlite
AppDomain-com.tencent.xin/Documents/<MD5(wxid)>/DB/MM_*.sqlite     # 分库（按 talker 哈希）
AppDomain-com.tencent.xin/Documents/<MD5(wxid)>/Img/               # 图片
AppDomain-com.tencent.xin/Documents/<MD5(wxid)>/Audio/             # 语音 aud
AppDomain-com.tencent.xin/Documents/<MD5(wxid)>/Video/             # 视频
AppDomain-com.tencent.xin/Documents/<MD5(wxid)>/OpenData/          # 收藏文件
AppDomain-com.tencent.xin/Documents/MMappedKV/                     # MMKV
AppDomain-com.tencent.xin/Documents/LoginInfo2.dat                 # 当前登录
```

- **wxid 反推**：`Documents/MMappedKV/account/account.<n>` 或 `MMappedKV/mmsetting.archive.<wxid>`，文件名直接含 wxid。

### 3.2 关键表（MM.sqlite，**通常无密码**）
- `Chat_<MD5(talker)>`：每个会话一张表。`MesLocalID, CreateTime, Type, Des, ImgStatus, Message, MesSvrID`。
- `Friend`/`Friend_<groupid>`：联系人。
- `Chat_*` 表需要在 `WCDB_Contact.sqlite.Friend` 里查到 `userName`，再算 MD5(userName) 拼表名 → 反向定位会话。

```sql
-- 列出所有会话表
SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'Chat_%';
-- 某个会话
SELECT datetime(CreateTime,'unixepoch','localtime'), Des, Type, Message
FROM Chat_<md5> ORDER BY CreateTime;
```
- `Des=0` 自己发，`Des=1` 对方发。
- `Type` 含义同 Android（1 文字 3 图 34 语音 43 视频 47 表情 49 链接/转账/红包 10000 系统）。

### 3.3 朋友圈
- `SnsMicroMsg.db`（Android）/ `sns.db`（iOS）：`SnsInfo` 表，`Content` 是 BLOB protobuf；用 `blackboxprotobuf`/`protoc` 反解。
- 图片/视频缓存在 `Sns/` 子目录，FTS5 索引在 `FTS5IndexMicroMsg.db`。

---

## 4. PC 微信取证

### 4.1 路径
```
Windows: %USERPROFILE%\Documents\WeChat Files\<wxid>\
  ├─ Msg\                # SQLCipher 数据库（MSG0.db..MSG9.db, MicroMsg.db, Misc.db, Media.db, Emotion.db, FTSContact.db）
  ├─ FileStorage\        # 文件 / 图片（dat 加密）/ 视频
  │   ├─ MsgAttach\<日期>\Image\          # .dat 文件
  │   └─ Image\
  ├─ Multimedia\         # 视频/语音
  └─ config\             # AccInfo.dat 等
```

### 4.2 密钥提取（关键考点）
- 微信 PC 主进程内存中保存 64 字节十六进制密钥（128 hex chars），位于 `WeChatWin.dll` 静态偏移 + 当前用户结构体。
- **方法**：
  1. 进程在线 → 用 [PyWxDump](https://github.com/xaoyaoo/PyWxDump) / [WeChatMsg](https://github.com/LC044/WeChatMsg) 自动提取。
  2. 全内存 dump（`procdump.exe -ma WeChat.exe`）后离线扫描 64 字节高熵串。
  3. 已知签名：`MSG0.db` 前 16 字节是 salt，PRAGMA `kdf_iter=64000`、`cipher_page_size=4096`、`HMAC=ON`、`HMAC_SHA1`、`PBKDF2_HMAC_SHA1`（**与 Android 旧版不同！**）。

```bash
pip install pywxdump
wxdump all          # 自动找进程提取
wxdump db -k <key> -i MSG0.db -o decrypted/   # 解密
```

### 4.3 PC 解密参数
```sql
PRAGMA key="x'<128 hex>'";
PRAGMA cipher_page_size=4096;
PRAGMA kdf_iter=64000;
PRAGMA cipher_hmac_algorithm=HMAC_SHA1;
PRAGMA cipher_kdf_algorithm=PBKDF2_HMAC_SHA1;
```

### 4.4 .dat 文件解密（PC 图片 + Android 图片同算法）
- 微信 PC / Android 都把图片用**单字节 XOR**加密；密钥从 dat 头几个字节与已知 JPEG/PNG/GIF magic 异或推算。
- **不需要** UIN / wxid / SQLCipher 密码——纯文件级。
- **同设备同账户内 key 是固定值**（不同账户/不同设备 key 不同）。
```python
def decrypt_wx_dat(dat_path, out_path=None):
    """微信 Dat 文件解密：自动推 key + 还原原图（JPG/PNG/GIF/BMP）"""
    SIGS = {b'\xff\xd8': '.jpg', b'\x89\x50': '.png',
            b'\x47\x49': '.gif', b'\x42\x4d': '.bmp'}
    data = open(dat_path, 'rb').read()
    for sig, ext in SIGS.items():
        k = data[0] ^ sig[0]
        if data[1] ^ sig[1] == k:
            out_path = out_path or dat_path + ext
            open(out_path, 'wb').write(bytes(b ^ k for b in data))
            return out_path, k, ext
    return None, None, None
```
> 现成工具：**WxDatViewer 2.5**（吾爱破解）/ **wechat-dump** / **WeChat Image Decoder**。

### 4.4.1 PC 微信图片 / 视频路径演进（**版本敏感，必背**）
| 版本 | 图片 | 视频 / 文件 |
| --- | --- | --- |
| **v3.7.0.26 之前** | `Documents\WeChat Files\<wxid>\FileStorage\Image\` | `FileStorage\{Video,File}\` |
| **v3.7.0.26 ~ v3.9.9.35** | `Documents\WeChat Files\<wxid>\FileStorage\MsgAttach\<MD5(微信ID)>\{Image,Thumb}\` ← 按好友/群分桶 | 同左旧位置 |
| **v3.9.9.35 之后** | **图片仍在 MsgAttach** | 视频/文件回滚到旧位置 |
| **v4.x（NT 风格新版）** | `Tencent\xwechat_files\<wxid>\msg\attach\<hash>\...` 完全重构 | 同上 |

**MsgAttach 子目录命名规律**：`MD5(微信原始 ID 字符串)`；可枚举所有好友 wxid/群 ID 反推哪个 MD5 对应谁。

### 4.4.2 微信收藏图片三处并存缓存（**易漏点**）
> 微信收藏夹的图片**同时存在 3 个缓存位置**，名称都一样：`WeChat Files\<wxid>\Fav\<sub>/`，但有的明文、有的 Dat 加密；**收藏后再转发的图片会被微信再次压缩** → 收藏副本与转发副本 SHA256 完全不同。
- 取证报告若问"原始收藏图 vs 转发图"——必须**同时**计算两个 hash 并标注差异。

### 4.5 关键表（PC）
- `MSG.db`：`MSG` 表（StrTalker 是聊天对象 wxid，CreateTime 秒，StrContent 文字/XML，CompressContent，BytesExtra protobuf 含发送人/被引用消息）。
- `MicroMsg.db`：`Contact`（昵称、备注、UserName）、`ChatRoom`（群成员 RoomData blob）、`Session`（会话列表）。
- `MediaMSG.db`：语音 silk → 用 PyWxDump 转 mp3。
- `OpenIMContact.db`：企业微信外部联系人。

---

## 5. 关键消息类型解码（Android/iOS 通用）

### 5.1 type=49 子类型（XML 内 `<msg><appmsg type=N>`）
| 子 type | 含义 |
| --- | --- |
| 1 | 链接卡片 |
| 3 | 音乐 |
| 5 | 网页 / 公众号文章 |
| 6 | 文件 |
| 8 | 表情（GIF） |
| 17 | 实时位置共享结束 |
| 19 | 合并转发（含 `<recordxml>`，可递归还原原会话） |
| 33 | 小程序 |
| 36 | 小程序消息卡 |
| 51 | 视频号视频 |
| 53 | 群接龙 |
| 57 | 引用回复（`<refermsg>` 指向 `svrid`） |
| 2000 | 转账（含 `transferid`、金额、状态） |
| 2001 | 红包（含 `nativeurl`、金额） |

```bash
# 用 xmllint/python 提取
python -c "import xml.etree.ElementTree as ET,sys;r=ET.fromstring(sys.argv[1]);print(r.find('.//appmsg').attrib)"
```

### 5.2 转账还原
- type=49 子 type=2000，`<wcpayinfo><paymsgid>` 唯一标识，`<feedesc>` 是金额（如 `￥100.00`），`<pay_memo>` 备注。
- 配合 `Wallet_data.bin` / `payinfo.db` 可看历史。

### 5.3 引用回复
- `<refermsg><svrid>` 指向被引用消息的 `msgSvrId`，跨 `message` 表回查。

### 5.4 合并转发
- `<recordxml><datalist><dataitem>` 每条 dataitem 是一条原消息，递归解析。

---

## 6. 朋友圈（SNS）

### 6.1 Android
- `SnsMicroMsg.db.SnsInfo`：`userName, createTime, type, content(BLOB protobuf), attrBuf`
- `content` 字段是 protobuf，主要字段：
  - 1: id
  - 2: userName
  - 4: createTime
  - 5: nickname
  - 6: contentDesc（文字）
  - 10: media list（图片/视频 url）
  - 14: location

```bash
pip install blackboxprotobuf
python -c "import blackboxprotobuf as p,sys;d,t=p.decode_message(open(sys.argv[1],'rb').read());import json;print(json.dumps(d,indent=2,ensure_ascii=False))" content.bin
```

### 6.2 评论 / 点赞
- `SnsComment` 表，`commentflag=1` 评论、`=2` 点赞。

### 6.3 媒体缓存
- `Sns/<MD5>/` 下子目录，文件名为 SHA1。

---

## 7. 多账号 / wxid 求解

### 7.1 wxid 来源
- `MMSetting.archive`（NSKeyedArchiver bplist）→ `m_userName` 字段。
- `LoginInfo2.dat`（iOS）/ `auth_info_key_prefs.xml`（Android）。
- `MMappedKV/account/` 文件名直接含 wxid。
- PC 端 `WeChat Files\<wxid>\` 目录名。

### 7.2 多账号区分
- Android `MicroMsg/<MD5(mm+uin)>` 多个目录 → 每个 uin 对应一账号。
- iOS `Documents/<MD5(wxid)>` 多个目录 → 每个 wxid 对应一账号。
- 用 `LoginInfo2.dat` 看 **当前登录**；用 `MMappedKV/last_login_wxid` 看最近。

---

## 8. MMKV / KeyValueDB

### 8.1 MMKV（Tencent 开源 KV 存储）
- 路径：`MMKV/` 下若干文件 + `<id>.crc`。
- 二进制结构：长度前缀 + protobuf 序列化值；可加密（AES-CFB）。
- 工具：[mmkv-parser](https://github.com/SoraYukino/mmkv-parser)、[MMKVTool](https://github.com/yangchong211/YCAndroidTool)、官方 `MMKV` 库读取。

```python
# 用官方库读未加密的 mmkv
import mmkv
mmkv.MMKV.initializeMMKV("/path/to/MMKV/parent")
kv = mmkv.MMKV("default")
print(kv.allKeys())
print(kv.getString("some_key"))
```

### 8.2 微信中常见 mmkv 命名
- `mmkv_account_<uin>`：账户信息
- `mmkv_runtime`：运行时配置
- `mmkv_kv_comm_prefs_<uin>`：通用偏好
- `WCDB_*`：WCDB 配置

---

## 9. PC 端 ↔ 手机端交叉验证

### 9.1 同一账号双端表
| 字段 | Android | iOS | PC |
| --- | --- | --- | --- |
| 消息 | `message.msgSvrId` | `Chat_*.MesSvrID` | `MSG.MsgSvrID` |
| 时间 | `createTime` (ms) | `CreateTime` (s) | `CreateTime` (s) |
| 对象 | `talker` (wxid/群 id) | `Chat_<MD5>` 表名 | `StrTalker` |

### 9.2 实战
- **手机消息缺失** → 查 PC `MSG.db`（PC 消息默认全部下载，可补全已删除）。
- **PC 漫游**：消息漫游开启后，PC 数据可能比手机还全（手机是滚动清理）。
- **跨端时间差**：PC 端 `CreateTime` 是接收时间，手机是发出时间，可能差几秒。

---

## 10. 决策树

```
拿到微信检材
├─ Android
│   ├─ 已 root + 数据齐 → IMEI(默认值优先) + uin → key=MD5(IMEI+uin)[:7] → sqlcipher_export → 解析
│   ├─ 未 root（备份/克隆）→ 看是否有 EnMicroMsg.db；ADB 备份默认排除微信
│   └─ 7.0+ WCDB → 多 MSG*.db 分库 → 按 talker 哈希拼接
├─ iOS
│   ├─ 备份/越狱 → 找 Documents/<MD5(wxid)>/DB/MM.sqlite（多无密码）
│   └─ 多账号 → MMappedKV/account 列 wxid → 选目标
├─ PC
│   ├─ 进程在线 → PyWxDump 内存提 key → 解 MSG*.db
│   └─ 仅备份 → 找 wechat key.bin / 内存 dump 离线扫
└─ 仅有局部痕迹（缩略图/语音）→ image2/voice2 + 文件名规则反查 message
```

---

## 11. 命令速查

```bash
# Android：从 shared_prefs 找 uin
strings auth_info_key_prefs.xml | grep -i uin
strings system_config_prefs.xml | grep -i uin

# 计算微信目录 MD5(mm+uin)
python -c "import hashlib,sys;print(hashlib.md5(('mm'+sys.argv[1]).encode()).hexdigest())" 1234567890

# 计算 EnMicroMsg key
python -c "import hashlib,sys;print(hashlib.md5((sys.argv[1]+sys.argv[2]).encode()).hexdigest()[:7])" 1234567890ABCDEF 1234567890

# sqlcipher 解密旧版微信
sqlcipher EnMicroMsg.db <<EOF
PRAGMA key='abc1234';
PRAGMA cipher_use_hmac=OFF;
PRAGMA cipher_page_size=1024;
PRAGMA kdf_iter=4000;
ATTACH DATABASE 'plain.db' AS p KEY '';
SELECT sqlcipher_export('p');
DETACH DATABASE p;
.exit
EOF

# silk 转 wav
./silk-v3-decoder/converter.sh msg_xx.amr wav

# PC 端 PyWxDump
pip install pywxdump
wxdump all
wxdump db -k <128hex> -i MSG0.db -o out/

# 朋友圈 protobuf
python -c "import blackboxprotobuf as p;d,t=p.decode_message(open('sns.bin','rb').read());import json;print(json.dumps(d,indent=2,ensure_ascii=False))"
```

---

## 12. 常见坑

1. **uin 符号问题**：Java int 32 位有符号溢出，uin 在 xml 里可能是负数，求 key 时必须按字符串原样拼接。
2. **IMEI 默认值**：Android 10+ 大概率是 `1234567890ABCDEF`，先试这个再试真实 IMEI。
3. **EnMicroMsg.db 只是消息库**：联系人/朋友圈在 `SnsMicroMsg.db`、`MicroMsg.db`，别只解一个就交差。
4. **PC vs 手机参数不同**：PC 微信 `kdf_iter=64000, page=4096, HMAC=ON`；旧版 Android `4000, 1024, HMAC=OFF`；混用必失败。
5. **撤回消息**：`message` 表里 type=10002 系统消息会留"xx 撤回了一条消息"；原消息 BLOB 可能仍在 WAL/free page。
6. **`-wal`/`-shm` 必须一起拷**，否则最近聊天可能缺。
7. **图片缩略图与原图分两个文件**：`bigImgPath` 才是高清原图，没下载过就只有缩略。
8. **群聊 talker** 是 `<群 id>@chatroom`，发言人 wxid 在 `content` 前缀 `<wxid>:\n`，要切开。
9. **语音 amr 实际是 silk-v3**：必须用 silk 解码器，普通 amr 播放器播不出来。
10. **iOS 多账号**：`Documents/` 下多个 MD5 子目录，先用 `MMappedKV/account` 锁当前账号。
11. **PC `MSG*.db` 分库**：`MSG0..MSG9` 按 talker 哈希分桶，跨库查需要 UNION ALL。
12. **`BytesExtra` 是 protobuf**：群聊发言人 wxid 在这里面（PC 端），别只看 StrContent。

---

## 13. 交叉链接
- `ios_forensics.md`：iOS 备份/越狱/Domain 全景
- `extraction_methods.md`：root/逻辑/物理提取
- `log_and_data_parsing.md`：SQLCipher/MMKV/Protobuf 通用解析
- `apk_crypto_analysis.md`：APK 内密钥提取通法
- `geolocation_forensics.md`：实时位置共享/朋友圈位置
- `timestamps_reference.md`：13 位 ms / Mac AbsTime 换算
- `solved/pattern_wechat_db_decrypt.md`：微信旧版解密 SOP
