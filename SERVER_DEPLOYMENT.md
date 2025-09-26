# 🚀 C-Agent 服务器部署指南

本指南将帮助您将C-Agent项目部署到Linux服务器上。

## 📋 前置要求

- Ubuntu/Debian服务器 (推荐 Ubuntu 20.04+)
- Root权限或sudo权限
- 服务器已配置SSH访问
- 至少1GB内存，10GB存储空间

## 🔑 SSH连接信息

根据提供的公钥，您的SSH连接信息：
```
SSH公钥: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRoof...
密钥ID: skey-76qwvajd
```

## 📤 第一步：上传项目文件

### 方法1: 使用SCP上传（推荐）

```bash
# 在本地项目目录下执行
scp -r ./* username@your-server-ip:/tmp/c-agent-upload/

# 或者打包上传
tar -czf c-agent.tar.gz --exclude='.git' --exclude='__pycache__' *
scp c-agent.tar.gz username@your-server-ip:/tmp/
```

### 方法2: 使用Git克隆

```bash
# 在服务器上执行
git clone YOUR_REPOSITORY_URL /tmp/c-agent-upload
```

### 方法3: 创建上传脚本

我已经为您创建了一个自动上传脚本 `upload.sh`

## 🛠 第二步：执行部署脚本

```bash
# 连接到服务器
ssh username@your-server-ip

# 如果是SCP上传的文件
sudo mv /tmp/c-agent-upload /opt/c-agent

# 如果是tar包
cd /tmp && tar -xzf c-agent.tar.gz
sudo mv c-agent /opt/

# 执行部署脚本
cd /opt/c-agent
sudo bash deploy.sh
```

## 🔧 部署脚本功能

`deploy.sh` 脚本将自动完成：

1. **系统更新** - 更新系统包
2. **软件安装** - 安装Python3、Nginx、Git等
3. **用户创建** - 创建专用的c-agent用户
4. **环境配置** - 设置Python虚拟环境
5. **依赖安装** - 安装Flask、OpenAI等依赖
6. **Gunicorn配置** - 配置WSGI服务器
7. **Systemd服务** - 创建系统服务
8. **Nginx反向代理** - 配置Web服务器
9. **防火墙设置** - 开放必要端口
10. **服务启动** - 启动所有服务

## 🌐 访问应用

部署完成后，您可以通过以下地址访问：

- **HTTP**: `http://your-server-ip`
- **如果有域名**: `http://your-domain.com`

## 📊 服务管理命令

```bash
# 查看服务状态
sudo systemctl status c-agent

# 启动/停止/重启服务
sudo systemctl start c-agent
sudo systemctl stop c-agent
sudo systemctl restart c-agent

# 查看日志
sudo journalctl -u c-agent -f

# 查看Nginx状态
sudo systemctl status nginx
sudo nginx -t  # 测试配置

# 查看应用日志
sudo tail -f /var/log/c-agent/error.log
sudo tail -f /var/log/c-agent/access.log
```

## 🔒 安全配置

### SSL证书配置（推荐）

```bash
# 安装Certbot
sudo apt install certbot python3-certbot-nginx

# 获取SSL证书（替换your-domain.com）
sudo certbot --nginx -d your-domain.com

# 自动续期
sudo systemctl enable certbot.timer
```

### 防火墙状态检查

```bash
# 查看防火墙状态
sudo ufw status

# 如需开放其他端口
sudo ufw allow 端口号
```

## 🐛 故障排除

### 常见问题

1. **服务启动失败**
   ```bash
   sudo journalctl -u c-agent --no-pager
   sudo systemctl status c-agent
   ```

2. **Nginx配置错误**
   ```bash
   sudo nginx -t
   sudo tail /var/log/nginx/error.log
   ```

3. **Python依赖问题**
   ```bash
   sudo -u c-agent /opt/c-agent/venv/bin/pip list
   sudo -u c-agent /opt/c-agent/venv/bin/pip install -r /opt/c-agent/requirements.txt
   ```

4. **权限问题**
   ```bash
   sudo chown -R c-agent:c-agent /opt/c-agent
   sudo chmod +x /opt/c-agent/*.py
   ```

### 检查端口占用

```bash
# 检查端口5000是否被占用
sudo netstat -tlnp | grep 5000
sudo lsof -i :5000
```

### 重新部署

```bash
# 停止服务
sudo systemctl stop c-agent

# 更新代码（如果需要）
cd /opt/c-agent
# 上传新文件...

# 重新安装依赖
sudo -u c-agent /opt/c-agent/venv/bin/pip install -r requirements.txt

# 重启服务
sudo systemctl restart c-agent
sudo systemctl restart nginx
```

## 🔄 更新应用

### 使用Git更新

```bash
cd /opt/c-agent
sudo -u c-agent git pull origin main
sudo -u c-agent /opt/c-agent/venv/bin/pip install -r requirements.txt
sudo systemctl restart c-agent
```

### 手动更新

1. 上传新文件到服务器
2. 替换 `/opt/c-agent/` 中的文件
3. 重启服务

## 📈 监控和维护

### 性能监控

```bash
# 查看系统资源使用
htop
df -h
free -m

# 查看应用进程
ps aux | grep gunicorn
```

### 日志轮转

系统会自动处理日志轮转，也可以手动配置：

```bash
# 编辑logrotate配置
sudo nano /etc/logrotate.d/c-agent
```

### 备份

```bash
# 备份应用配置和数据
sudo tar -czf c-agent-backup-$(date +%Y%m%d).tar.gz /opt/c-agent/config.json /opt/c-agent/history.log

# 数据库备份（如果使用）
# mysqldump 或 pg_dump 命令
```

## 🌟 性能优化建议

1. **调整Gunicorn workers数量**
   - 编辑 `/opt/c-agent/gunicorn_config.py`
   - 根据CPU核心数调整workers

2. **启用Nginx缓存**
   - 配置静态文件缓存
   - 启用Gzip压缩

3. **监控内存使用**
   - 定期检查内存使用情况
   - 必要时重启服务释放内存

## 📞 技术支持

如果遇到问题：

1. 查看日志文件确定错误原因
2. 检查服务状态和配置
3. 确认网络连接和防火墙设置
4. 验证文件权限和用户配置

---

**🎉 恭喜！您的C-Agent现在已经在服务器上运行了！**