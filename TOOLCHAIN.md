# AutoForensicAI v2 — 工具链完整方案

> 覆盖取证、渗透、CTF 实战中所有可能场景的工具集，分为 MCP 集成工具和传统工具两大类。

---

## 一、设计原则

1. **MCP 优先**：能通过 MCP 协议让 AI 直接调用的工具优先集成
2. **离线可用**：所有工具必须支持本地部署，不依赖云服务
3. **平台兼容**：标注 Windows/Linux 兼容性，提供跨平台替代方案
4. **按需加载**：不一次全装，通过 `toolchain.yaml` 注册，按角色/场景按需安装
5. **冲突检测**：记录端口、依赖冲突，安装前自动检查

---

## 二、MCP Server 集成方案

### 2.1 核心 MCP Server（必装）

| MCP Server | 功能 | 来源 | 优先级 |
|---|---|---|---|
| **BurpMCP** | Burp Suite 代理历史、站点地图、扫描器、Repeater | `PortSwigger/mcp-server` | P0 |
| **KaliMCP** | 远程调用 Kali Linux 上的所有工具 | `Wh0am123/MCP-Kali-Server` | P0 |
| **SOLVE-IT MCP** | 电子取证知识库查询（DFT/DFW/DFM） | `CKE-Proto/solve_it_mcp` (已在 references/) | P0 |
| **Volatility MCP** | 内存取证分析（进程、网络、注册表） | `bornpresident/Volatility-MCP-Server` | P0 |
| **Autopsy MCP** | 磁盘取证平台（Sleuth Kit 图形界面） | Autopsy 4.23+ 内置 | P1 |
| **MCP Forensic Toolkit** | 日志分析、文件完整性、关联引擎 | `axdithyaxo/mcp-forensic-toolkit` | P1 |

### 2.2 渗透测试 MCP Server（按需）

| MCP Server | 功能 | 来源 | 适用场景 |
|---|---|---|---|
| **Nmap MCP** | 端口扫描、服务指纹、NSE 脚本 | `cyproxio/mcp-for-security` | 网络侦察 |
| **SQLMap MCP** | SQL 注入自动化检测 | `cyproxio/mcp-for-security` | Web 渗透 |
| **Nuclei MCP** | 模板化漏洞扫描（4000+ 模板） | `cyproxio/mcp-for-security` | 漏洞扫描 |
| **FFUF MCP** | Web 目录/参数 Fuzz | `cyproxio/mcp-for-security` | Web 渗透 |
| **Masscan MCP** | 高速端口扫描 | `cyproxio/mcp-for-security` | 大规模扫描 |
| **SSLScan MCP** | SSL/TLS 配置分析 | `cyproxio/mcp-for-security` | 加密分析 |
| **WPScan MCP** | WordPress 漏洞扫描 | `cyproxio/mcp-for-security` | CMS 渗透 |
| **MobSF MCP** | 移动应用安全测试 | `cyproxio/mcp-for-security` | 手机取证 |
| **Amass MCP** | 子域名枚举 + OSINT | `cyproxio/mcp-for-security` | 侦察 |
| **Katana MCP** | Web 爬虫（含 JS 解析） | `cyproxio/mcp-for-security` | Web 取证 |
| **httpx MCP** | HTTP 探测和技术识别 | `cyproxio/mcp-for-security` | 侦察 |
| **Gowitness MCP** | 网页截图和侦察 | `cyproxio/mcp-for-security` | 证据固定 |

### 2.3 综合型 MCP Server（高级替代）

| MCP Server | 规模 | 来源 | 说明 |
|---|---|---|---|
| **HexStrike AI** | 150+ 工具 | `morpheusc/Hexstrike-AI` | 全能型，含取证/逆向/密码/云安全/CTF |
| **PentestMCP** | 20+ 工具 | `ramkansal/pentestMCP` | 学术验证（arXiv 论文支持） |
| **zebbern-kali-mcp** | 17 模块 | `zebbern/zebbern-kali-mcp` | Flask 架构，模块化好 |
| **Burp AI Agent** | Burp + AI 深度集成 | `six2dez/burp-ai-agent` | 支持本地模型 + 被动/主动扫描 |
| **PentestAgent** | Metasploit + PTT | `GH05TCREW/pentestagent` | 自主渗透测试，Kali Docker 集成 |

---

## 三、传统工具清单（按取证/渗透领域分类）

### 3.1 电子取证

#### 磁盘取证
| 工具 | 功能 | 平台 | 安装方式 |
|---|---|---|---|
| **Autopsy** | 数字取证平台（GUI） | Win/Linux | 官方安装包 |
| **Sleuth Kit (TSK)** | 底层磁盘分析（fls, icat, mmls） | Win/Linux | `apt install sleuthkit` |
| **FTK Imager** | 磁盘镜像和证据采集 | Win | 官方安装包 |
| **Arsenal Image Mounter** | 取证镜像挂载（E01/DD/VMDK） | Win | 官方安装包 |
| **binwalk** | 固件分析和嵌入文件提取 | Win/Linux | `pip install binwalk` |
| **foremost** | 文件雕刻恢复 | Linux | `apt install foremost` |
| **testdisk / photorec** | 分区恢复 / 文件恢复 | Win/Linux | `apt install testdisk` |
| **dd / dc3dd** | 磁盘镜像和哈希验证 | Linux | 系统内置 / `apt install dc3dd` |

#### 内存取证
| 工具 | 功能 | 平台 | 安装方式 |
|---|---|---|---|
| **Volatility 3** | 内存分析框架 | Win/Linux | `pip install volatility3` |
| **Volatility 2** | 旧版内存分析（更多插件） | Win/Linux | `pip install volatility` |
| **Rekall** | Google 内存取证框架 | Win/Linux | `pip install rekall` |
| **WinPmem / LiME** | 内存采集工具 | Win / Linux | 手动下载 |

#### 网络取证
| 工具 | 功能 | 平台 | 安装方式 |
|---|---|---|---|
| **Wireshark / tshark** | 流量捕获和深度分析 | Win/Linux | 官方安装包 / `apt install tshark` |
| **NetworkMiner** | 网络取证分析（自动提取文件） | Win/Linux | 官方安装包 |
| **tcpdump** | 命令行抓包 | Linux | `apt install tcpdump` |
| **Zeek (Bro)** | 网络安全监控 | Linux | `apt install zeek` |
| **PcapXray** | PCAP 可视化分析 | Win/Linux | `pip install pcapxray` |

#### 注册表 / 事件日志
| 工具 | 功能 | 平台 | 安装方式 |
|---|---|---|---|
| **Registry Explorer** | Windows 注册表浏览分析 | Win | Eric Zimmerman 工具集 |
| **RegRipper** | 注册表自动提取 | Win/Linux | `apt install regripper` |
| **EvtxECmd** | Windows 事件日志解析 | Win | Eric Zimmerman 工具集 |
| **Chainsaw** | 快速 Windows 事件日志分析 | Win/Linux | GitHub Release |
| **Hayabusa** | Windows 事件日志分析（Sigma） | Win/Linux | GitHub Release |

#### 手机取证
| 工具 | 功能 | 平台 | 安装方式 |
|---|---|---|---|
| **ALEAPP** | Android 日志事件解析 | Win/Linux | `pip install aleapp` |
| **iLEAPP** | iOS 日志事件解析 | Win/Linux | `pip install ileapp` |
| **Andriller** | Android 数据提取 | Win/Linux | GitHub |
| **ADB** | Android 调试桥 | Win/Linux | Android Platform Tools |
| **libimobiledevice** | iOS 设备交互 | Linux/Mac | `apt install libimobiledevice` |
| **MVT** | 移动设备验证工具包（Pegasus） | Win/Linux | `pip install mvt` |

#### 浏览器 / 应用取证
| 工具 | 功能 | 平台 | 安装方式 |
|---|---|---|---|
| **Hindsight** | Chrome/Chromium 浏览器历史 | Win/Linux | `pip install pyhindsight` |
| **KAPE** | 快速证据采集和分析 | Win | 下载 |
| **MFTECmd** | $MFT 文件解析 | Win | Eric Zimmerman 工具集 |
| **PECmd** | Prefetch 解析 | Win | Eric Zimmerman 工具集 |
| **LECmd** | LNK 文件解析 | Win | Eric Zimmerman 工具集 |

### 3.2 隐写术 / 编码

| 工具 | 功能 | 平台 | 安装方式 |
|---|---|---|---|
| **steghide** | JPEG/BMP 隐写 | Linux | `apt install steghide` |
| **zsteg** | PNG/BMP LSB 隐写 | Linux | `gem install zsteg` |
| **stegsolve** | 图像隐写分析（多层） | Win/Linux | Java jar |
| **exiftool** | 元数据提取 | Win/Linux | `apt install libimage-exiftool-perl` |
| **stegseek** | steghide 暴力破解 | Linux | GitHub Release |
| **Aperi'Solve** | 在线隐写综合分析 | Web | 本地部署 Docker |
| **DeepSound** | 音频隐写 | Win | 独立程序 |
| **SilentEye** | 图片/音频隐写 | Win/Linux | 独立程序 |
| **openstego** | 通用隐写和水印 | Win/Linux | GitHub |
| **CyberChef** | 编码/解码/加密瑞士军刀 | Web/本地 | GitHub Release (静态 HTML) |

### 3.3 密码学

| 工具 | 功能 | 平台 | 安装方式 |
|---|---|---|---|
| **John the Ripper** | 密码哈希破解 | Win/Linux | `apt install john` |
| **Hashcat** | GPU 加速密码破解 | Win/Linux | 官方安装包 |
| **RsaCtfTool** | RSA 攻击工具 | Linux | `pip install rsactftool` |
| **SageMath** | 数学计算（密码分析） | Win/Linux | 官方安装包 |
| **z3-solver** | SMT 约束求解 | Win/Linux | `pip install z3-solver` |

### 3.4 逆向工程

| 工具 | 功能 | 平台 | 安装方式 |
|---|---|---|---|
| **Ghidra** | 逆向工程（NSA） | Win/Linux | 官方安装包 |
| **IDA Free** | 反汇编器 | Win/Linux | 官方安装包 |
| **radare2 / rizin** | 逆向框架 | Win/Linux | GitHub Release |
| **GDB + pwndbg/GEF** | 调试器 | Linux | `apt install gdb` + pip |
| **pwntools** | CTF 漏洞利用开发 | Linux | `pip install pwntools` |
| **angr** | 符号执行 | Win/Linux | `pip install angr` |
| **Binary Ninja** | 逆向工程平台（商业） | Win/Linux | 付费 |
| **UPX** | 加壳/脱壳 | Win/Linux | GitHub Release |
| **DIE (Detect It Easy)** | 查壳 | Win/Linux | GitHub Release |

### 3.5 Web 安全 / 渗透

| 工具 | 功能 | 平台 | 安装方式 |
|---|---|---|---|
| **Burp Suite** | Web 渗透测试平台 | Win/Linux | 官方安装包 |
| **OWASP ZAP** | 开源 Web 扫描器 | Win/Linux | 官方安装包 |
| **sqlmap** | SQL 注入自动化 | Win/Linux | `pip install sqlmap` |
| **Nmap** | 端口/服务扫描 | Win/Linux | 官方安装包 |
| **Nuclei** | 模板化漏洞扫描 | Win/Linux | `go install` |
| **ffuf** | Web Fuzz | Win/Linux | `go install` |
| **Gobuster** | 目录枚举 | Win/Linux | `go install` |
| **Hydra** | 在线暴力破解 | Linux | `apt install hydra` |
| **Metasploit** | 渗透测试框架 | Win/Linux | Kali 内置 |
| **Nikto** | Web 服务器扫描 | Win/Linux | `apt install nikto` |
| **dirsearch** | 目录发现 | Win/Linux | `pip install dirsearch` |
| **wfuzz** | Web Fuzzer | Win/Linux | `pip install wfuzz` |
| **commix** | 命令注入测试 | Win/Linux | `pip install commix` |

### 3.6 OSINT / 情报

| 工具 | 功能 | 平台 | 安装方式 |
|---|---|---|---|
| **Sherlock** | 社交媒体用户名搜索 | Win/Linux | `pip install sherlock` |
| **theHarvester** | 邮箱和子域名收集 | Win/Linux | `pip install theHarvester` |
| **Maltego** | 图形化情报分析 | Win/Linux | 官方安装包 |
| **SpiderFoot** | 自动化 OSINT | Win/Linux | `pip install spiderfoot` |
| **Recon-ng** | OSINT 框架 | Win/Linux | `pip install recon-ng` |

---

## 四、工具注册格式（toolchain.yaml）

```yaml
# tools/nmap.yaml
tool:
  id: nmap
  name: Nmap
  version: "7.95"
  category: [reconnaissance, network]
  roles: [network_analyst, server_analyst, main]
  platforms:
    windows:
      install: "choco install nmap"
      binary: "C:\\Program Files\\Nmap\\nmap.exe"
      verify: "nmap --version"
    linux:
      install: "apt install -y nmap"
      binary: "/usr/bin/nmap"
      verify: "nmap --version"
  mcp_server:
    available: true
    source: "cyproxio/mcp-for-security/nmap-mcp"
    config:
      command: "python"
      args: ["nmap_mcp/server.py"]
  dependencies:
    - libpcap     # Linux only
  ports: []       # No port conflicts
  tags: [port-scan, service-detection, nse-scripts]
```

---

## 五、MCP 配置生成

系统根据当前角色和场景自动生成 MCP 配置：

```yaml
# 自动生成的 mcp_config.json 示例（给 mobile_analyst 角色）
{
  "mcpServers": {
    "volatility": {
      "command": "python",
      "args": ["volatility_mcp/server.py"],
      "env": {"VOLATILITY_BIN": "/usr/bin/vol3"}
    },
    "solveit": {
      "command": "python",
      "args": ["solve_it_mcp/src/server.py"],
      "cwd": "tools/solve_it_mcp"
    },
    "mobsf": {
      "command": "python",
      "args": ["mobsf_mcp/server.py"],
      "env": {"MOBSF_API_KEY": "${MOBSF_API_KEY}"}
    }
  }
}
```

---

## 六、一键部署脚本设计

```
bootstrap.ps1 -Action install-tools -Role mobile_analyst -Platform windows
bootstrap.ps1 -Action install-tools -Role all -Platform linux
bootstrap.ps1 -Action check-tools                    # 检查已安装工具
bootstrap.ps1 -Action generate-mcp-config -Role main # 生成 MCP 配置
bootstrap.ps1 -Action verify-all                     # 验证所有工具可用
```

**安装流程**：
1. 读取 `toolchain/*.yaml` 中当前角色需要的工具
2. 检查当前平台 → 选择对应安装命令
3. 冲突检测（端口、依赖版本）
4. 执行安装 + 验证
5. 生成 MCP 配置文件
6. 输出安装报告

---

## 七、工具与角色映射

| 角色 | 必装工具 | MCP Server | 可选工具 |
|---|---|---|---|
| **main** (总指挥) | — | SOLVE-IT MCP | CyberChef |
| **mobile_analyst** | ADB, ALEAPP, iLEAPP, MVT | MobSF MCP, Volatility MCP | Andriller |
| **computer_analyst** | Autopsy, Volatility, RegRipper | Autopsy MCP, Volatility MCP | KAPE, Chainsaw |
| **server_analyst** | Nmap, tshark, Volatility | Nmap MCP, Volatility MCP | Zeek |
| **network_analyst** | Wireshark, tshark, tcpdump | Nmap MCP | NetworkMiner, Zeek |
| **web_analyst** | Burp Suite, sqlmap, ffuf | BurpMCP, SQLMap MCP, Nuclei MCP | ZAP, dirsearch |
| **crypto_analyst** | John, Hashcat, RsaCtfTool, z3 | — | SageMath |
| **reverse_analyst** | Ghidra, radare2, pwntools | — | angr, IDA Free |
| **stego_analyst** | steghide, zsteg, exiftool | — | stegsolve, Aperi'Solve |
| **osint_analyst** | theHarvester, Sherlock | Amass MCP, httpx MCP | Maltego, SpiderFoot |

---

## 八、参考项目快速对照

| 需求 | 推荐项目 | 说明 |
|---|---|---|
| Burp + AI 联动 | `PortSwigger/mcp-server` + `six2dez/burp-ai-agent` | 官方 MCP + 增强版（支持本地模型） |
| Kali 全工具 AI 调用 | `Wh0am123/MCP-Kali-Server` | 592 star, 最流行的 Kali MCP |
| 安全工具 MCP 集合 | `cyproxio/mcp-for-security` | 22 个独立 MCP server, Docker 支持 |
| 150+ 工具一站式 | `morpheusc/Hexstrike-AI` | 全能型，但依赖重 |
| 学术验证的渗透 MCP | `ramkansal/pentestMCP` | arXiv 论文背书 |
| 取证专用 MCP | `axdithyaxo/mcp-forensic-toolkit` | 日志/文件/关联分析 |
| 内存取证 MCP | `bornpresident/Volatility-MCP-Server` | Volatility 3 封装 |
| 磁盘取证 MCP | Autopsy 4.23+ 内置 | Sleuth Kit 图形化 |
