# Webshell Traffic Analysis — Quick Reference

> Source: Forensics-Wiki (forensics-wiki.com)

## Tool Overview
| Tool | Encryption | Key Feature |
|------|-----------|-------------|
| 菜刀 (Chopper) | URL encode + Base64 | Fixed `&z0=QGluaV9zZXQ...` parameter |
| 蚁剑 (AntSword) | Configurable encoders | Parameter names like `_0x...=` |
| 冰蝎 (Behinder) | AES + Base64 | Rotating User-Agent, `e45e329feb5d925b` default key |
| 哥斯拉 (Godzilla) | XOR + Base64 | Cookie ends with `;`, response = md5[:16]+base64+md5[16:] |

## 菜刀 (Chopper)
- **Payload location**: Request body, URL encoded + Base64
- **Identifiers**:
  - `eval` or `assert`, `base64_decode` in payload
  - Fixed parameter `&z0=QGluaV9zZXQ...` (Base64 of `@ini_set("display_errors","0");@set_time_limit(0);...`)
  - PHP: `eval(base64_decode($_POST[action]))`

## 蚁剑 (AntSword)
- Based on Chopper source, similar base traffic
- **Default**: URL encoding only, two requests per connection
- **1st request**: `@ini_set("display_errors","0")...` (same as Chopper)
- **2nd request**: List host directory
- **Key identifier**: Parameter names starting with `_0x` (e.g., `_0x3f2a=...`)
- Supports multiple encoders/plugins → encrypted traffic hard to detect

## 冰蝎 (Behinder)

### v2.0
- AES + Base64, three requests
- 1st GET: server generates key → session
- 2nd GET: fetch 16-byte AES key
- 3rd: AES encrypted communication

### v3.0
- AES + Base64, two requests
- **Key**: Fixed = `md5("rebeyond")[:16]` = `e45e329feb5d925b`
- No key exchange
- 1st request: connection test
- 2nd request: `phpinfo` etc.

### v4.0
- Custom encryption protocol
- No fixed password concept
- **Weak features**:
  - `Accept: application/json, text/javascript, */*; q=0.01`
  - `Content-type: Application/x-www-form-urlencoded`
  - Rotating User-Agent (built-in list)
  - Port range ~49700 (incrementing)
  - `Connection: Keep-Alive`
  - Fixed request/response byte headers
  - Default key still `e45e329feb5d925b`

## 哥斯拉 (Godzilla)

### Encryption Flow
1. Base64 encode original data
2. XOR with key (md5 of custom key)[:16]
3. Base64 encode again
4. URL encode
5. Prepend password parameter name

### Detection Features
- **User-Agent**: Exposes JDK version (default, modifiable)
- **Accept**: `text/html, image/gif, image/jpeg, *; q=.2, /; q=.2`
- **Cookie**: Ends with semicolon `;` (strong feature)
- **Response structure**: `md5[:16] + base64_data + md5[16:]`

## Wireshark Filters
```
# Find potential webshell POST requests
http.request.method == "POST" && http contains "eval"
http.request.method == "POST" && http contains "base64_decode"
http.request.method == "POST" && http contains "assert"

# Behinder default key
http contains "e45e329feb5d925b"

# Chopper z0 parameter
http contains "&z0=QGluaV9zZXQ"

# Godzilla cookie ending with semicolon
http.cookie matches ".*;$"
```
