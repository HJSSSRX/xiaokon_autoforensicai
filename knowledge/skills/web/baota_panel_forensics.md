# 宝塔面板取证 — Quick Reference

> Source: Forensics-Wiki (forensics-wiki.com)

## 判断是否使用宝塔
1. 访问服务器 IP → 是否跳转宝塔错误页面
2. 访问 `http://{ip}:8888` (旧版默认端口，新版随机)

## 关键文件路径
```bash
# 面板绑定账号信息
cat /www/server/panel/data/userInfo.json

# 安全入口路径
cat /www/server/panel/data/admin_path.pl

# IP访问限制
cat /www/server/panel/data/limitip.conf

# BasicAuth 认证 (MD5加密)
cat /www/server/panel/config/basic_auth.json

# 面板数据库 (SQLite)
/www/server/panel/data/default.db

# 网站配置
/www/server/panel/vhost/nginx/
/www/server/panel/vhost/apache/

# 网站根目录 (默认)
/www/wwwroot/

# 数据库备份
/www/backup/database/

# 网站备份
/www/backup/site/

# 面板日志
/www/server/panel/logs/
```

## 关闭安全限制
```bash
# 交互式菜单
bt

# 常用序号:
# 14 - 修改面板端口
# 5  - 修改面板密码
# 24 - 关闭动态口令认证
```

### 手动关闭
```bash
# 删除安全入口限制
rm -rf /www/server/panel/data/admin_path.pl

# 删除IP访问限制
rm -rf /www/server/panel/data/limitip.conf
```

## 网站重构思路
1. **直接启动**: 在仿真服务器中启动网站，修改本机 hosts 文件
2. **本地运行**: 导出网站源码+数据库到本地
   - 注意匹配程序版本 (PHP/MySQL/Python等)
   - 修改: 默认文档、伪静态、网站目录配置

## 绕过手机号强制登录
- 参考: https://github.com/weiwang3056/baota_release
- 仅用于取证环境，生产环境慎用
