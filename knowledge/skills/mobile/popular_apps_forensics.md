# 主流 App 取证速查（QQ / TIM / 抖音 / 快手 / 支付宝 / 淘宝 / 美团）

> 适用：除微信外的高频考察 App。题目特征：见到 `MobileQQ`、`com.tencent.mobileqq`、`com.tencent.tim`、`com.ss.android.ugc.aweme`、`com.smile.gifmaker`、`com.eg.android.AlipayGphone`、`alipay`、`taobao`、`pcache`、`Msg.db`、`SLog`、`hummerdb`、`AwemeIM` 等。

---

## 1. QQ / TIM

### 1.1 包名与路径
| 平台 | 包名 / 路径 |
| --- | --- |
| Android QQ | `/data/data/com.tencent.mobileqq/`（数据 `/data/user/0/com.tencent.mobileqq/databases/` `Tencent/MobileQQ/`） |
| Android TIM | `/data/data/com.tencent.tim/` |
| iOS QQ | `AppDomain-com.tencent.mqq` 或 `com.tencent.qq` 下 `Documents/` |
| PC QQ NT（新版） | `%USERPROFILE%\Documents\Tencent Files\<QQ号>\nt_qq\nt_data\Db\nt_msg.db` |
| PC QQ 旧版 | `Tencent Files\<QQ号>\Msg2.0.db / FTS\Msg2.0_*.db` |

### 1.2 Android QQ 数据库
- 主库：`/data/data/com.tencent.mobileqq/databases/<QQ号>.db`（**SQLite 明文 + 字段 RC4/XOR 加密**）。
- 关键表：
  - `mr_friend_<QQ号>_New` 联系人
  - `mr_troop_<QQ号>` 群
  - `mr_msg_<QQ号>_<好友QQ>` 私聊（每个聊天对象一张表，**表名结尾的 friendQQ 哈希过**）
  - `mr_troop_msg_<QQ号>_<群号>` 群聊
  - `slowtable_msg_<QQ号>` 兜底
- **字段加密**：`msgData` 字段是 RC4 加密；密钥：`MD5(uin+"_groupkey...")`/或 `MD5(uin)` 截取，**版本相关**，需查当版逆向（资源商业取证软件已固化）。
- **uin** 即 QQ 号，明文。

```sql
-- 列出某好友消息表
.tables mr_msg_<QQ>_*
-- 朋友列表
SELECT uin, name, remark FROM mr_friend_<QQ>_New;
-- 群列表
SELECT troopuin, troopname FROM mr_troop_<QQ>;
```

### 1.3 媒体
- 图片：`Tencent/MobileQQ/chatpic/chatimg/<hash>` 直接 jpg/gif（无加密）。
- 缩略图：`Thumbs/`、`shortvideo_thumbs/`。
- 视频：`Tencent/MobileQQ/shortvideo/`。
- 文件：`Tencent/QQfile_recv/`（从 QQ 接收的文件，**未删除直接看**，是常考 dump 点）。
- 语音：`Tencent/MobileQQ/diskcache/` `record/`，amr/silk。

### 1.4 PC QQ NT（9.x 新版，2023+）
- 数据库 `nt_msg.db` 是 **SQLCipher**（与微信 PC 类似），密钥从 `QQ.exe` 进程内存读取。
- 工具：[QQ-Msg-Backup](https://github.com/) / [QQNT-Decrypt](https://github.com/) / 部分版本 **Tencent NT 已改用本地 sqlite3 + AES-256-GCM 自定义**，参数随版本更新。
- 关键表：`group_msg_table`、`c2c_msg_table`、`buddy_info`、`group_info`。
- **NT 数据交叉**：`nt_qq/nt_data/Pic/` 图片 dat 文件，单字节 XOR 同微信 PC 解法。

### 1.5 iOS QQ
- 数据库：`AppDomain-com.tencent.mqq/Library/Application Support/QQ/<QQ号>/QQ.db` 等，**SQLite 明文**居多。
- 表名规则：`tb_c2cMsg_<好友QQ>`、`tb_groupMsg_<群号>`。

### 1.6 关键考点
- **QQ 号 = uin**，直接可见。
- **撤回消息**：`mr_msg_*` 表 `msgtype=10002` 是撤回提示；原消息可能在 `slowtable_*` 或 free page。
- **临时会话/陌生人消息**：单独表 `mr_msg_<QQ>_temp_*`。
- **QQ 邮箱附件 / 文件中转站**：`Tencent/QQfile_recv/` + `MobileQQ/.tmp/`。
- **PC 端 NT 与移动端不同步**：手机端清理过的 PC 仍保留。

---

## 2. 抖音（Aweme）

### 2.1 包名 / 路径
| 平台 | 路径 |
| --- | --- |
| Android 抖音 | `com.ss.android.ugc.aweme`（国内）/ `com.zhiliaoapp.musically`（TikTok） |
| iOS 抖音 | `AppDomain-com.ss.iphone.ugc.Aweme` |
| 抖音极速版 | `com.ss.android.ugc.aweme.lite` |

### 2.2 关键文件
| 路径 | 内容 |
| --- | --- |
| `databases/im.db` / `aweme_im_<uid>.db` | **私信数据库**（SQLCipher 加密，key 从 `MMKV/im_<uid>` 或 `shared_prefs/aweme_im_keva.xml` 取，部分版本 key 是 device_id+iid） |
| `databases/cache.db` | 视频缓存索引 |
| `databases/pcache.db` | 浏览/搜索/点赞缓存 |
| `databases/feedback.db` | 用户反馈 |
| `shared_prefs/applog_stats.xml` | **device_id, iid, install_id**（逆向 key 必备） |
| `shared_prefs/aweme_user.xml` | 当前账号 uid、sec_uid、昵称 |
| `files/applog_v2/` | 行为日志（点击、播放、停留） |
| `files/awemeIM/` | 私信附件 |
| `cache/aweme_video_cache/` | 视频缓存 |
| `cache/image_cache/` | 图片缓存 |
| `MMKV/` | 大量配置和登录态 |

### 2.3 用户身份
- `uid`：抖音内部 64 位用户 ID。
- `sec_uid`：对外加密 ID（用于 URL `https://www.douyin.com/user/<sec_uid>`）。
- `aweme_id`：视频 ID（雪花 ID，含时间戳）。
- 以上都在 `shared_prefs/aweme_user.xml` 或 `MMKV/aweme_user_<uid>` 里。

### 2.4 私信解密
- `im.db` 是 SQLCipher，key 多版本演进：
  - 早期（2019-2021）：`MD5(device_id+iid+uid)` 截取。
  - 近版：从 `MMKV/im_<uid>` 二进制读 32 字节随机 key（需 mmkv 解析）。
  - 也有版本 key 存 Keystore（需 root + frida hook）。
- 商业取证软件已固化各版本逻辑；手工逆向 `libcom.ss.android.ugc.aweme.so` 找 `sqlite3_key` 调用。

### 2.5 浏览/搜索/点赞
- `pcache.db`：表 `recently_watch`、`search_history`、`liked_aweme`（部分版本字段名不同）。
- 搜索词也见 `shared_prefs/search_history.xml` 或 `MMKV/search_history_<uid>`。
- 视频点赞：`liked_aweme.aweme_id, like_time`。

### 2.6 视频元信息
- 缓存视频文件名通常是 `<aweme_id>.mp4` 或 hash；可用 `aweme_id` 反查抖音 web。
- `aweme_id` 雪花结构：高 41 位是毫秒时间戳（自抖音 epoch，不同版本 epoch 不同，**经验**：`(aweme_id >> 22) + epoch_ms = 发布时间`，epoch ≈ `1262304000000`（2010-01-01）—— 实测以正负 8 位以内为准，多版本拼对照）。

### 2.7 行为日志
- `files/applog_v2/queue/` 下大量 `*.log` 文件，每行一个 JSON 事件，含 `event_v3`：`page_show`、`video_play`、`like`、`share`、`comment`。
- 解析后可还原**完整浏览轨迹**。

```bash
strings -n 8 *.log | grep -E '"event":"(page_show|video_play|like|share|comment)"'
```

---

## 3. 快手（GifShow）

### 3.1 包名
- `com.smile.gifmaker`（快手）/ `com.kuaishou.nebula`（极速版）/ `com.kwai.video`（一些海外版）。

### 3.2 关键路径
| 路径 | 内容 |
| --- | --- |
| `databases/kwai_*.db` | 多个分库 |
| `databases/im.db` / `messagesdk.db` | 私信 |
| `shared_prefs/passport_user.xml` | 当前账号 user_id、token |
| `shared_prefs/last_login_user.xml` | 历史登录 |
| `MMKV/` | KV 配置 |
| `cache/.video/` | 视频缓存 |
| `files/log/` | 客户端日志 |

### 3.3 私信
- `messagesdk.db`：SQLCipher，key 同样从 device 生成；表 `Message`、`Conversation`、`KwaiConversation`。

### 3.4 浏览/点赞/关注
- `databases/photo_*.db` 浏览历史
- `MMKV/like_photo_history` 点赞
- `databases/follow_history.db` 关注

---

## 4. 支付宝（Alipay）

### 4.1 包名 / 路径
- Android：`com.eg.android.AlipayGphone`
- iOS：`AppDomain-com.alipay.iphoneclient`

### 4.2 关键文件（Android）
| 路径 | 内容 |
| --- | --- |
| `databases/alipayUser_<userid>` | 主用户库（SQLCipher） |
| `databases/mobilegw.db` | 网关请求缓存 |
| `databases/cdp.db` | 营销/广告 |
| `databases/messageboxstatic_<userid>` | 消息盒子（账单提醒、好友消息） |
| `databases/socialChat_<userid>.db` | 支付宝聊天 |
| `databases/contact_account_<userid>.db` | 通讯录 |
| `databases/userconfig_<userid>.db` | 配置 |
| `shared_prefs/` `userdata_<userid>` `last_login_user_id` | 当前/最近账号 |
| `files/storage/<userid>/` | 文件缓存 |

### 4.3 账号识别
- `userid`：支付宝 16 位用户 ID（不同于手机号，但可关联）。
- `loginId`：登录账号（手机号/邮箱）。
- 来源：`shared_prefs/last_login_user_id` 或 `userdata_<userid>.xml`。

### 4.4 账单 / 转账
- 主要账单不在本地（实时云端拉取）；本地仅有缓存：
  - `databases/alipayUser_<userid>` 中 `bill_*` 表
  - `messageboxstatic_<userid>` 含转账/收款通知（**关键考点**）
  - `socialChat_<userid>.db.chatmsg` 含红包/转账消息体
- 红包/转账消息 `msgType=300/301`，BLOB 字段 protobuf 解。

### 4.5 解密
- `alipayUser_<userid>` 是 SQLCipher，key 在 `libcommonbiz_lib.so` / `libalipay_secstore.so` 内，与 IMEI/AndroidID/userid 派生，**版本敏感**。
- 实战：商业取证软件已固化；自研需 frida hook `sqlite3_key`/`sqlite3_key_v2`。

### 4.6 收藏 / 卡包 / 健康码
- `databases/<userid>_card.db`：卡包（包含**电子身份证、社保卡**等敏感信息）。
- `databases/<userid>_health.db`：行程码/健康码缓存。
- `databases/h5_*` H5 离线包缓存（含小程序元数据）。

---

## 5. 淘宝 / 闲鱼

### 5.1 包名
- 淘宝：`com.taobao.taobao`
- 天猫：`com.tmall.wireless`
- 闲鱼：`com.taobao.idlefish`

### 5.2 关键文件
| 路径 | 内容 |
| --- | --- |
| `databases/mtopdb.db` | mtop 网络请求缓存（**含 API 返回值**，账单/订单可见） |
| `databases/AlivcMixedDB.db` | 直播 |
| `databases/main.db` | 通用 |
| `databases/im_*.db` / `databases/openIm_*.db` | 阿里旺旺/闲鱼私信（SQLCipher） |
| `shared_prefs/userdata.xml` | 用户 ID、nick |
| `MMKV/` | KV |

### 5.3 阿里 IM（旺旺）
- 闲鱼/淘宝 IM 在 `openIm_<userid>.db`，SQLCipher，key 派生自 `userid+device`。
- 群组叫"会话组"；私聊 `cid`/`ccode` 命名。

---

## 6. 美团 / 大众点评

### 6.1 包名
- 美团：`com.sankuai.meituan`
- 美团外卖：`com.sankuai.meituan.takeoutnew`
- 大众点评：`com.dianping.v1`

### 6.2 关键文件
| 路径 | 内容 |
| --- | --- |
| `databases/orderlist.db` `localorder.db` | 订单缓存 |
| `databases/searchhistory.db` | 搜索历史 |
| `databases/locate.db` | 位置历史 |
| `databases/poi.db` | 浏览过的 POI |
| `shared_prefs/` `mt_passport_userinfo` | 账号 |

- 大部分 SQLite 明文，订单、搜索、定位历史直接读。

---

## 7. 通用挖掘技巧（适用所有 App）

1. **找当前账号** → `shared_prefs/*user*` `*passport*` `*account*` `*login*` 或 `MMKV/*user*` `*account*`。
2. **找历史账号** → `last_login_*` `account_list*`。
3. **找消息库** → `databases/*msg*` `*im*` `*chat*` `*talk*`，先 `file *.db` 看是否 SQLite，再 `xxd | head` 看是否 SQLCipher（前 16 字节非 `SQLite format 3`）。
4. **找搜索历史** → `*search*` `*history*` xml/db/MMKV。
5. **找浏览/观看历史** → `*recent*` `*watched*` `*viewed*` `*history*` `pcache*`。
6. **找位置** → `*location*` `*locate*` `*geo*` `*city*`。
7. **找视频/图片缓存** → `cache/*` `files/*media*` `*image*` `*video*`。
8. **找加密 key** → `MMKV/`、`libnative*.so` strings、Keystore（root 后 dump `/data/misc/keystore`）。
9. **网络日志兜底** → `*applog*` `*alog*` `*qlog*`，多为 protobuf/json 行式日志，行为最全。
10. **关注/粉丝/好友** → `*friend*` `*follow*` `*contact*`。

---

## 8. 决策树

```
拿到主流 App 检材
├─ 先确定账号
│   └─ shared_prefs / MMKV → 当前 user_id / wxid / uin / sec_uid
├─ 再分类
│   ├─ 私信 → 找 im/msg.db（多 SQLCipher）→ 提 key（MMKV/SO/Keystore）→ 解密
│   ├─ 浏览/搜索 → pcache/history db → 多明文，直接读
│   ├─ 账单/订单 → mtop/alipay 缓存 db + 消息盒子（取证软件已固化解析）
│   └─ 媒体缓存 → cache/ 下用文件头识别（jpg/mp4/silk）
└─ 实在解不开 → applog/网络日志取行为兜底
```

---

## 9. 命令速查

```bash
# 列出 App 所有 sqlite
find /data/data/<pkg> -name "*.db" -exec file {} \;

# 看是否 SQLCipher（前 16 字节非 SQLite 头说明加密）
xxd EnMicroMsg.db | head -1

# MMKV 解析
python -m mmkv_parser /path/to/MMKV/<file>

# applog 行为筛
grep -hE '"event":"[a-z_]+"' files/applog_v2/queue/*.log | sort -u

# 抖音 aweme_id 时间反推（粗略）
python -c "import sys;a=int(sys.argv[1]);ms=(a>>22)+1262304000000;import datetime;print(datetime.datetime.fromtimestamp(ms/1000))" <aweme_id>

# 支付宝 socialChat 提 protobuf
python -c "import blackboxprotobuf as p;d,t=p.decode_message(open('msg.bin','rb').read());import json;print(json.dumps(d,indent=2,ensure_ascii=False))"

# QQ chatpic 直接 file
file Tencent/MobileQQ/chatpic/chatimg/*
```

---

## 10. 常见坑

1. **QQ 字段加密**：`mr_msg_*.msgData` 是 RC4 加密，sqlite 能打开 ≠ 能直接读消息内容，需要按版本解。
2. **PC QQ NT 与旧版完全不同**：旧版 `Msg2.0.db` 工具不能用于 NT，找对应版本工具。
3. **抖音 device_id ≠ android_id**：`shared_prefs/applog_stats.xml` 里的 `device_id` 是抖音服务器分配的；与系统 device id 不同。
4. **MMKV 加密**：默认不加密，但部分 App（抖音、快手、支付宝）开了 AES-CFB，需要 cryptKey。
5. **支付宝账单云端拉取**：本地几乎没有完整账单，靠消息盒子+聊天 protobuf 兜底，别只看 `bill_*` 表。
6. **淘宝订单依赖 mtopdb**：网络缓存按时间滚动清理，超过 N 天就没了，时效性强。
7. **多账号**：QQ/支付宝路径里的 `<userid>` 是当前用户的；多账号时 `databases/` 下会有多套，别混。
8. **闲鱼 vs 淘宝 IM 数据库不在同一处**：闲鱼有自己的 `com.taobao.idlefish` 沙盒。
9. **抖音 `sec_uid` 是对外 URL 友好 ID，`uid` 才是数据库主键**，别混用。
10. **iOS App 数据多分散在 Documents / Library / tmp / SharedContainer**，看 `Manifest.db` 把所有 domain 列出来防漏。

---

## 10.5 移动端本地大语言模型（LLM）取证（**2026 FIC 新增题型**）

> 嫌疑人可能用本地 LLM 跑通 + 离线提问"如何洗钱/如何搭赌博/如何换脸"等敏感问题，**云端取证抓不到，必须本地沙盒挖**。

### 10.5.1 主流 App 速查
| App | 包名 / iOS Bundle | 模型格式 | 对话存储 |
| --- | --- | --- | --- |
| **PocketPal AI** | `com.pocketpalai`（Android）/ `com.a-ghorbani.pocketpalai`（iOS） | GGUF | `databases/chat.db` 或 Realm `default.realm` |
| **MLC Chat** | `ai.mlc.mlcchat` | MLC 自有量化 | `files/dist/...`、`databases/chat.db` |
| **Maid**（开源 GGUF Chat） | `com.danemadsen.maid` | GGUF | sqlite |
| **Llama.cpp Android demo** | 各 fork（`com.llama.android`） | GGUF | 文件 / sqlite |
| **Layla**（商业本地 LLM） | `com.layla` | 加密 GGUF | sqlite + 加密 |
| **Sherpa-mnn** / **MNN-LLM** | 阿里 MNN | MNN 自有 | sqlite/json |
| **ChatterUI** | `com.vali98.chatterui` | GGUF/远程 | sqlite |
| **AI Smith** / **Private LLM** | iOS 闭源 | 自有 | Core Data |

### 10.5.2 关键路径（PocketPal 为例）
```
/data/com.pocketpalai/
├── databases/
│   ├── chat.db                      # ★ 对话主库（messages 表，含 role/content/createdAt）
│   ├── model_stats.db               # 加载/卸载历史
│   └── settings.db
├── files/
│   ├── models/                      # ★ 模型文件
│   │   ├── Qwen3.5-7B-Q4_K_M.gguf
│   │   └── Llama-3.2-3B-Instruct.Q4_K_M.gguf
│   └── tmp/
└── shared_prefs/
    └── selected_model.xml
```

### 10.5.3 模型文件取证
- **GGUF 格式头**：前 4 字节 `GGUF` 魔数，后跟 version + tensor_count + metadata_kv_count；
- **工具**：
  ```bash
  # 一行看模型名 / 量化 / 参数
  python3 -c "
  from gguf import GGUFReader
  r = GGUFReader('Qwen3.5-7B-Q4_K_M.gguf')
  for k in ['general.name','general.architecture','general.quantization_version','tokenizer.ggml.tokens']:
      try: print(k, '=', r.fields[k].parts[r.fields[k].data[0]])
      except: pass
  "
  # 或直接 strings 看头几百字节
  xxd Qwen3.5-7B-Q4_K_M.gguf | head -30
  strings -n 8 Qwen3.5-7B-Q4_K_M.gguf | head -50
  ```
- **元数据**含：模型名 / 架构（llama/qwen/phi）/ 量化方式（Q4_K_M / Q8_0）/ 上下文长度 / 词表 / 训练数据来源（如填了的话）。

### 10.5.4 对话取证（**这是题问"提问几次""问了什么"的来源**）
```sql
-- PocketPal chat.db
SELECT role, content, created_at, conversation_id
FROM messages
WHERE role = 'user'              -- ★ 题问"主动提问几次" 数 user 行
ORDER BY created_at;

-- 全部对话还原
SELECT role, content, datetime(created_at/1000, 'unixepoch', '+8 hours') AS t
FROM messages
ORDER BY conversation_id, created_at;
```

### 10.5.5 比赛常见提问类型 & 答案策略
| 题问 | 答案位置 |
| --- | --- |
| **使用什么 AI App** | 包名 + App 列表，火眼/取证大师能识别新版 |
| **使用什么模型 + 版本** | `files/models/*.gguf` 文件名 + GGUF 元数据 `general.name` |
| **模型量化方式** | 文件名末尾 `Q4_K_M` / `Q8_0` 等 |
| **主动提问几次** | `messages` 表 `role='user'` 计数 |
| **问了什么敏感问题** | `messages.content` 直接读 |
| **首次/最后一次使用** | `messages.created_at` MIN/MAX |
| **是否本地推理** | 看是否有 `*.gguf` + 是否有联网调用（结合流量包） |

### 10.5.6 与"云端 AI（ChatGPT/Claude/通义/文心一言）"的区别
| 项 | 本地 LLM | 云端 AI |
| --- | --- | --- |
| 模型存沙盒 | ✅ 必有 GGUF | ❌ |
| 对话本地数据库 | ✅ 全量本地 | ⚠️ 部分缓存 + 云端可调 |
| 流量特征 | 仅初次下模型有大流量 | 每次提问都有 HTTPS POST |
| 取证抓手 | 沙盒 | 沙盒 + 云端调取 + 抓包 |
| 云端 App 包名 | — | ChatGPT `com.openai.chatgpt`；通义 `com.aliyun.tongyi`；文心 `com.baidu.newapp`；豆包 `com.larus.nova`；Kimi `com.moonshot.kimichat`；DeepSeek `com.deepseek.chat` |

### 10.5.7 反取证
1. 嫌疑人删模型 → 沙盒 chat.db 仍残；SQLite 删除恢复也常见；
2. 嫌疑人改模型文件名伪装为 `xxx.bin/.dat` → 看 `GGUF` 魔数；
3. 嫌疑人用 Termux 跑 `llama.cpp` 命令行 → 痕迹在 `~/.bash_history` 和 Termux 沙盒；
4. iOS 端 Private LLM / AI Smith 用 keychain 加密 → 用 keychain dump。

---

## 11. 交叉链接
- `wechat_deep_dive.md`：微信完整方法论
- `ios_forensics.md`：iOS Domain 全景
- `apk_crypto_analysis.md`：找 sqlite key 的 SO 逆向
- `log_and_data_parsing.md`：MMKV / Protobuf / SQLCipher 通用解析
- `app_data_analysis.md`：行为数据八大类型速查
- `crypto_currency_forensics.md`：钱包类 App（Tron/MetaMask 等）方法
