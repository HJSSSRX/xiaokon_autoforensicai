# Pattern 07: WPS .et 文件隐藏字段提取

> 来源：FIC2026 C09/C10 — 保险柜编号/密码

---

## 题型特征

- 检材中有 `.et` 文件（WPS Spreadsheet）
- 题目要求提取"隐藏"的编号或密码
- 文件可能有密码保护

## 解题流程

### 1. 识别文件结构
`.et` 文件本质是 ZIP 压缩包（类似 .xlsx）：
```bash
file xxx.et           # 应显示 "Zip archive data"
unzip -l xxx.et       # 列出内部文件
```

### 2. 提取 XML 内容
```python
import zipfile, re
z = zipfile.ZipFile('xxx.et')
for name in z.namelist():
    if name.endswith('.xml'):
        data = z.read(name).decode('utf-8', 'ignore')
        # 搜索隐藏属性
        for m in re.finditer(r'descr="([^"]*)"', data):
            print(name, m.group(1))
```

### 3. 关键 XML 路径
- `drs/shapexml.xml` — 形状对象的描述属性（`descr`），常用于隐藏文本
- `drs/downrev.xml` — 低版本兼容数据
- `xl/worksheets/sheet1.xml` — 单元格数据

### 4. 提取隐藏数字
`descr` 属性通常包含 6 位数字，可能是密码或编号：
```
descr="565033"   ← 可能是保险柜编号
descr="538037"   ← 可能是密码
```

### 5. CSV 伴随文件
如果 `.et` 文件旁边有 `.csv`：
```bash
cat pass8.csv
# 重要密码,,,
# 虚拟卡,,cvv955,4413 5399 0161 6210
```

## FIC2026 实战数据

| 文件 | descr 值 |
|------|---------|
| 保险箱的秘密.et | `565033` |
| pass1.et | `538037` |
| pass3.et | `593037` |
| pass5.et | `669033` |
| pass6.et | `583196` |
| pass8.csv | cvv955, 虚拟卡号 |

## 可复现命令

```python
import zipfile, glob, re
for f in glob.glob('/tmp/*.et'):
    z = zipfile.ZipFile(f)
    for name in z.namelist():
        if name.endswith('.xml'):
            data = z.read(name).decode('utf-8', 'ignore')
            for m in re.finditer(r'descr="([^"]*)"', data):
                print(f, name, m.group(1))
```
