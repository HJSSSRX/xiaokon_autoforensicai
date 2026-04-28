# Playbook · Active Directory / 域横向分析

## 0. 判题模式

- "主体 X 对主体 Y 有什么控制权限"（GenericAll / WriteDacl / ForceChangePassword / AddMember / ...）
- "从某用户到域管的最短攻击路径"
- "域控里有几个用户 / 组 / 服务账号"
- 社工题：某用户的密码规律（结合画像推字典）

---

## 1. 检材形态

| 形态 | 特征 | 处理 |
|---|---|---|
| BloodHound 导出 zip | 内含 `*_users.json`、`*_groups.json`、`*_computers.json`、`*_sessions.json` 等 | 直接导入 neo4j |
| ntds.dit + SYSTEM hive | Windows 域控提取 | `impacket-secretsdump -ntds` |
| 域服务器的磁盘镜像 | 有 `C:\Windows\NTDS\` | 先用 SharpHound 离线模式采集，或手动解 ntds.dit |
| 域成员机器的内存 | 含 LSASS | `mimikatz` / `pypykatz` → 明文密码、Kerberos tickets |

---

## 2. BloodHound 分析流程

### 导入

```bash
# neo4j
docker run -d --rm -p 7474:7474 -p 7687:7687 \
    -e NEO4J_AUTH=neo4j/bloodhound neo4j:4.4

# BloodHound CE（社区版 4.x）
git clone https://github.com/BloodHoundAD/BloodHound
# 启动 GUI，连接 neo4j，拖 zip 进去
```

**平航杯风格**：可能直接给一个 `*.zip` BloodHound 数据，或者给一个已导入数据的 neo4j 数据库备份 (`neo4j-admin dump`)，需要 `load`。

### 关键 Cypher 查询

```cypher
-- 1. 某实体有什么权限（控制谁）
MATCH (a {name:'FILESERVER.XIAORANG.LAB'})-[r]->(b)
RETURN a.name, type(r), b.name

-- 2. 某实体被什么控制
MATCH (a)-[r]->(b {name:'XIAORANG.LAB'})
RETURN a.name, type(r), b.name

-- 3. 最短攻击路径
MATCH p=shortestPath(
  (u:User {name:'ZHANGXIN@XIAORANG.LAB'})-[*1..]->
  (d:Group {name:'DOMAIN ADMINS@XIAORANG.LAB'})
) RETURN p

-- 4. 从某用户到域的路径
MATCH p=allShortestPaths(
  (u:User {name:'ZHANGXIN@XIAORANG.LAB'})-[*1..]->
  (d:Domain {name:'XIAORANG.LAB'})
) RETURN p

-- 5. 枚举所有 Kerberoastable
MATCH (u:User {hasspn:true}) RETURN u.name

-- 6. ACL 异常（用户能改域 ACL）
MATCH p=(u:User)-[r:GenericAll|WriteDacl|Owns|AllExtendedRights]->(d:Domain)
RETURN p
```

### 权限边类型速查

| 边 | 含义 | 攻击 |
|---|---|---|
| `MemberOf` | 是成员 | 隐含权限继承 |
| `GenericAll` | 完全控制 | 几乎什么都能做 |
| `GenericWrite` | 写属性 | 改 servicePrincipalName → Kerberoast |
| `WriteDacl` | 改 ACL | 给自己加 GenericAll |
| `WriteOwner` | 改 owner | 先夺 owner 再改 ACL |
| `ForceChangePassword` | 改密码 | 直接接管 |
| `AddMember` | 加组 | 加入特权组（Domain Admins 等） |
| `AllowedToDelegate` | 约束委派 | S4U2Self/Proxy 冒充 |
| `AddAllowedToAct` | RBCD | 资源基约束委派 |
| `GetChanges` + `GetChangesAll` | DCSync 权限 | `secretsdump` 导全域 hash |

### 典型攻击路径写法

题目格式 `XXX@XX.XXX->XXXXXXXXXX.XXXXXXX.XXX->XXXXXXXX.XXX`：
- 第一段：起点用户 `ZHANGXIN@XIAORANG.LAB`
- 中间：控制的机器/用户，例如 `FILESERVER.XIAORANG.LAB`
- 终点：域 `XIAORANG.LAB`

边的类型可能要求写在箭头上或单独描述。看题目格式定。

---

## 3. ntds.dit 离线分析

```bash
# 需要：ntds.dit + SYSTEM hive
impacket-secretsdump -ntds ntds.dit -system SYSTEM LOCAL -outputfile $OUT/domain

# 产出：
# $OUT/domain.ntds       ← 所有用户 NTLM 哈希
# $OUT/domain.ntds.kerberos  ← Kerberos keys
```

找特定用户：
```bash
rg -i '^Administrator:' $OUT/domain.ntds
```

---

## 4. 靶场识别（"XIAORANG.LAB" 套路）

域名 `XIAORANG.LAB` 是 **春秋云境 / 小让靶场**的典型命名。如果检材里出现这类域名，说明题目参考了公开靶场：
- 靶场常用固定攻击链（密码喷洒 → 某用户本地管理员 → 访问某机器 → 拿到 ticket → 域控）
- 套路：先看 README 对 ZoneTransfer / SharpHound 导入后跑默认查询

**注意**：比赛会改用户名、改一两个关键权限，不能抄原靶场答案。

---

## 5. 邮件社工辅助

社工题经常给：
- 一本笔记 / 日记（找生日、宠物名、爱人姓名）
- 一个朋友圈 / 微博（找关键词）
- 一张照片（看 EXIF 或内容）

然后让你生成**针对性字典**：

```python
# 基础字典生成
from itertools import product
base = ['zhangsan', 'zs', 'zhangxin']
years = [str(y) for y in range(1990, 2005)]
dates = ['0526', '0105', '1231']    # 从日记提取的日期
specials = ['', '!', '@', '#', '123', '123!', '!@#']
with open('dict.txt','w') as f:
    for b, d, s in product(base, years+dates, specials):
        f.write(f'{b}{d}{s}\n')
```

---

## 6. 常见坑

- BloodHound 版本：CE (4.x/5.x) 和 legacy (3.x) 数据格式不同
- neo4j 5.x 语法和 4.x 略有差异（`size()` vs `count{}`）
- 域控时间不同步时 Kerberos 票据会出奇怪 TGS error
- `DOMAIN ADMINS@XX` 是组，`Administrator@XX` 是用户，别混
