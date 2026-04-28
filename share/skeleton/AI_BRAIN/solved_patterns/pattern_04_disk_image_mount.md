# 解题套路 04：磁盘镜像挂载分析

**适用场景**：需要挂载E01/RAW等磁盘镜像进行分析  
**解题时间**：2026-04-24  
**相关题目**：Q53, Q54, Q55

---

## 🎯 解题思路

1. **识别镜像格式**：E01, DD, RAW等
2. **选择挂载工具**：FTK Imager, ewfmount, losetup等
3. **挂载镜像**：创建挂载点并挂载
4. **分析文件系统**：浏览文件，提取关键数据

---

## 📋 操作步骤

### 1. 识别镜像格式
```bash
# 查看镜像文件信息
file disk_image.E01

# 使用ewfinfo查看E01信息
ewfinfo disk_image.E01

# 查看镜像大小
ls -lh disk_image.E01
```

### 2. 挂载E01镜像
```bash
# 方法1：使用ewfmount（推荐）
sudo mkdir /mnt/e01_mnt
sudo ewfmount disk_image.E01 /mnt/e01_mnt

# 方法2：使用FTK Imager（Windows）
# 在Windows中使用FTK Imager挂载

# 方法3：转换为raw后挂载
ewfexport disk_image.E01 -f raw -o disk_image.raw
sudo losetup /dev/loop0 disk_image.raw
sudo mount /dev/loop0 /mnt/disk_mnt
```

### 3. 浏览文件系统
```bash
# 查看挂载内容
ls -la /mnt/e01_mnt/

# 查看用户目录
ls -la /mnt/e01_mnt/Users/

# 查看特定用户目录
ls -la "/mnt/e01_mnt/Users/深情专一沼气王，她是我的生死劫/"
```

### 4. 查找关键文件
```bash
# 查找邮件客户端数据
find /mnt/e01_mnt -name "*mail*" -o -name "*Mail*" 2>/dev/null

# 查找数据库文件
find /mnt/e01_mnt -name "*.db" -o -name "*.sqlite" 2>/dev/null

# 查找配置文件
find /mnt/e01_mnt -name "*.xml" -o -name "*.json" -o -name "*.ini" 2>/dev/null
```

### 5. 分析邮件数据
```bash
# 查看邮件数据库
ls -la /mnt/e01_mnt/ProgramData/*/MailMasterData/

# 查看邮件附件
ls -la /mnt/e01_mnt/ProgramData/*/MailMasterData/*/parts/

# 查看邮件数据库结构
sqlite3 /mnt/e01_mnt/ProgramData/*/MailMasterData/*/mail.db ".tables"
```

---

## 🔍 关键点

1. **权限问题**：挂载需要sudo权限
2. **挂载点**：确保挂载点存在且为空
3. **只读挂载**：避免修改原始镜像
4. **路径处理**：中文路径需要正确处理

---

## 🛠️ 工具需求

- ewftools（libewf）
- FTK Imager（Windows）
- sqlite3
- find, grep等基础工具

---

## ⚠️ 注意事项

1. **镜像完整性**：确保镜像文件完整
2. **空间需求**：挂载需要足够磁盘空间
3. **权限设置**：正确设置挂载点权限
4. **中文支持**：确保文件系统支持中文

---

## 📊 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 挂载失败 | 镜像损坏 | 使用ewfverify检查 |
| 权限错误 | 权限不足 | 使用sudo挂载 |
| 中文乱码 | 编码问题 | 设置locale |
| 找不到文件 | 路径错误 | 使用find搜索 |

---

## 🔄 改进方向

1. 自动化挂载脚本
2. 镜像完整性检查
3. 批量文件提取
4. 增量分析支持

---

## 📝 成功案例

**邮件分析案例**：
- 镜像：`qq_pc.E01`
- 挂载点：`/mnt/qq_pc_mnt`
- 邮件路径：`/mnt/qq_pc_mnt/ProgramData/Netease/MailMasterData/`
- 成功提取：邮件数据库、附件

**恶意软件分析案例**：
- 镜像：`malware.E01`
- 挂载点：`/mnt/malware_mnt`
- 发现：`C:\Users\Public\Downloads\Haimuniu_VPN_Client.zip`
- 分析：.NET恶意软件，键盘记录功能

---

## 🔧 自动化脚本示例

```python
#!/usr/bin/env python3
import subprocess
import os
import json

def mount_e01(image_path, mount_point):
    """挂载E01镜像"""
    # 创建挂载点
    os.makedirs(mount_point, exist_ok=True)
    
    # 挂载镜像
    cmd = f"sudo ewfmount {image_path} {mount_point}"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    
    if result.returncode == 0:
        print(f"成功挂载到 {mount_point}")
        return True
    else:
        print(f"挂载失败：{result.stderr}")
        return False

def analyze_mail_data(mount_point):
    """分析邮件数据"""
    mail_path = f"{mount_point}/ProgramData"
    
    # 查找邮件客户端
    mail_clients = []
    for root, dirs, files in os.walk(mail_path):
        if "MailMasterData" in root:
            mail_clients.append(root)
    
    results = []
    for client in mail_clients:
        # 查找邮件数据库
        db_files = []
        for root, dirs, files in os.walk(client):
            for file in files:
                if file.endswith('.db'):
                    db_files.append(os.path.join(root, file))
        
        # 查找附件
        attachments = []
        for root, dirs, files in os.walk(client):
            if 'parts' in root:
                for file in files:
                    attachments.append(os.path.join(root, file))
        
        results.append({
            'client_path': client,
            'databases': db_files,
            'attachments': attachments
        })
    
    return results

def extract_attachments(attachments, output_dir):
    """提取附件"""
    os.makedirs(output_dir, exist_ok=True)
    
    extracted = []
    for attachment in attachments:
        # 复制附件到输出目录
        import shutil
        filename = os.path.basename(attachment)
        output_path = os.path.join(output_dir, filename)
        shutil.copy2(attachment, output_path)
        
        # 计算MD5
        import hashlib
        with open(output_path, 'rb') as f:
            md5 = hashlib.md5(f.read()).hexdigest()
        
        extracted.append({
            'original_path': attachment,
            'extracted_path': output_path,
            'md5': md5,
            'size': os.path.getsize(output_path)
        })
    
    return extracted

def main():
    image_path = "disk_image.E01"
    mount_point = "/mnt/disk_analysis"
    output_dir = "./extracted_files"
    
    # 挂载镜像
    if mount_e01(image_path, mount_point):
        # 分析邮件数据
        mail_data = analyze_mail_data(mount_point)
        
        # 提取附件
        all_attachments = []
        for client in mail_data:
            all_attachments.extend(client['attachments'])
        
        extracted = extract_attachments(all_attachments, output_dir)
        
        # 保存结果
        with open('analysis_results.json', 'w', encoding='utf-8') as f:
            json.dump({
                'mail_clients': mail_data,
                'extracted_files': extracted
            }, f, ensure_ascii=False, indent=2)
        
        print(f"分析完成，提取了 {len(extracted)} 个文件")

if __name__ == "__main__":
    main()
```
