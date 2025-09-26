#!/bin/bash
# C-Agent 服务器部署脚本
# Server Deployment Script for C-Agent

set -e  # 遇到错误立即退出

echo "🚀 开始部署 C-Agent 到服务器..."
echo "🚀 Starting C-Agent deployment to server..."
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
PROJECT_NAME="c-agent"
APP_USER="c-agent"
APP_DIR="/opt/$PROJECT_NAME"
NGINX_AVAILABLE="/etc/nginx/sites-available"
NGINX_ENABLED="/etc/nginx/sites-enabled"
SYSTEMD_DIR="/etc/systemd/system"

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "此脚本需要root权限运行"
        print_error "请使用: sudo bash deploy.sh"
        exit 1
    fi
}

# 更新系统
update_system() {
    print_status "更新系统包..."
    apt update && apt upgrade -y
    print_success "系统更新完成"
}

# 安装必要软件
install_dependencies() {
    print_status "安装必要软件..."
    
    # 安装基础软件
    apt install -y \
        python3 \
        python3-pip \
        python3-venv \
        nginx \
        supervisor \
        git \
        curl \
        wget \
        unzip \
        ufw
    
    print_success "软件安装完成"
}

# 创建应用用户
create_app_user() {
    print_status "创建应用用户..."
    
    if id "$APP_USER" &>/dev/null; then
        print_warning "用户 $APP_USER 已存在"
    else
        useradd --system --shell /bin/bash --home-dir $APP_DIR --create-home $APP_USER
        print_success "用户 $APP_USER 创建完成"
    fi
}

# 设置应用目录
setup_app_directory() {
    print_status "设置应用目录..."
    
    # 创建目录
    mkdir -p $APP_DIR
    chown $APP_USER:$APP_USER $APP_DIR
    
    # 创建虚拟环境
    sudo -u $APP_USER python3 -m venv $APP_DIR/venv
    
    print_success "应用目录设置完成"
}

# 部署应用代码（这里假设代码已经上传到服务器）
deploy_application() {
    print_status "部署应用代码..."
    
    # 如果应用目录中没有代码，提示用户上传
    if [ ! -f "$APP_DIR/app.py" ]; then
        print_warning "未在 $APP_DIR 中找到应用代码"
        print_status "请将C-Agent项目文件上传到 $APP_DIR"
        print_status "您可以使用以下方法之一："
        print_status "1. scp -r ./c-agent/* user@server:$APP_DIR/"
        print_status "2. git clone 您的仓库到 $APP_DIR"
        print_status "3. 手动上传文件"
        read -p "代码上传完成后按回车继续..."
    fi
    
    # 设置文件权限
    chown -R $APP_USER:$APP_USER $APP_DIR
    chmod +x $APP_DIR/*.py
    
    # 安装Python依赖
    print_status "安装Python依赖..."
    sudo -u $APP_USER $APP_DIR/venv/bin/pip install --upgrade pip
    
    if [ -f "$APP_DIR/requirements.txt" ]; then
        sudo -u $APP_USER $APP_DIR/venv/bin/pip install -r $APP_DIR/requirements.txt
        print_success "Python依赖安装完成"
    else
        print_warning "未找到 requirements.txt 文件"
    fi
}

# 配置Gunicorn
setup_gunicorn() {
    print_status "配置Gunicorn..."
    
    # 安装Gunicorn
    sudo -u $APP_USER $APP_DIR/venv/bin/pip install gunicorn
    
    # 创建Gunicorn配置文件
    cat > $APP_DIR/gunicorn_config.py << EOF
# Gunicorn配置文件
import multiprocessing

# 服务器socket
bind = "127.0.0.1:5000"
backlog = 2048

# Worker进程
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "sync"
worker_connections = 1000
timeout = 30
keepalive = 2

# 重启
max_requests = 1000
max_requests_jitter = 50
preload_app = True

# 日志
errorlog = "/var/log/c-agent/error.log"
accesslog = "/var/log/c-agent/access.log"
loglevel = "info"

# 进程命名
proc_name = "c-agent"

# 用户权限
user = "$APP_USER"
group = "$APP_USER"
EOF

    # 创建日志目录
    mkdir -p /var/log/c-agent
    chown $APP_USER:$APP_USER /var/log/c-agent
    
    chown $APP_USER:$APP_USER $APP_DIR/gunicorn_config.py
    print_success "Gunicorn配置完成"
}

# 配置Systemd服务
setup_systemd_service() {
    print_status "配置Systemd服务..."
    
    cat > $SYSTEMD_DIR/c-agent.service << EOF
[Unit]
Description=C-Agent Flask Application
After=network.target

[Service]
Type=notify
User=$APP_USER
Group=$APP_USER
RuntimeDirectory=c-agent
WorkingDirectory=$APP_DIR
Environment=PATH=$APP_DIR/venv/bin
ExecStart=$APP_DIR/venv/bin/gunicorn --config $APP_DIR/gunicorn_config.py app:app
ExecReload=/bin/kill -s HUP \$MAINPID
KillMode=mixed
TimeoutStopSec=5
PrivateTmp=true
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # 重载systemd并启用服务
    systemctl daemon-reload
    systemctl enable c-agent
    
    print_success "Systemd服务配置完成"
}

# 配置Nginx
setup_nginx() {
    print_status "配置Nginx..."
    
    # 获取服务器IP（用于默认配置）
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")
    
    cat > $NGINX_AVAILABLE/c-agent << EOF
server {
    listen 80;
    server_name $SERVER_IP localhost;  # 请替换为您的域名
    
    # 静态文件
    location /static/ {
        alias $APP_DIR/static/;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }
    
    # 上传文件
    location /uploads/ {
        alias $APP_DIR/uploads/;
        expires 1d;
    }
    
    # 应用程序
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket支持（如果需要）
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # 文件上传大小限制
    client_max_body_size 10M;
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1000;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}
EOF

    # 启用站点
    ln -sf $NGINX_AVAILABLE/c-agent $NGINX_ENABLED/
    
    # 删除默认站点（可选）
    rm -f $NGINX_ENABLED/default
    
    # 测试Nginx配置
    nginx -t
    
    print_success "Nginx配置完成"
}

# 配置防火墙
setup_firewall() {
    print_status "配置防火墙..."
    
    # 启用UFW
    ufw --force enable
    
    # 允许SSH
    ufw allow ssh
    ufw allow 22
    
    # 允许HTTP和HTTPS
    ufw allow 80
    ufw allow 443
    
    # 显示状态
    ufw status
    
    print_success "防火墙配置完成"
}

# 启动服务
start_services() {
    print_status "启动服务..."
    
    # 启动C-Agent应用
    systemctl start c-agent
    systemctl status c-agent --no-pager
    
    # 重启Nginx
    systemctl restart nginx
    systemctl status nginx --no-pager
    
    print_success "服务启动完成"
}

# 显示部署信息
show_deployment_info() {
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")
    
    echo ""
    echo "🎉 C-Agent 部署完成！"
    echo "=================================="
    echo "🌐 访问地址: http://$SERVER_IP"
    echo "📁 应用目录: $APP_DIR"
    echo "👤 应用用户: $APP_USER"
    echo "🔧 服务管理:"
    echo "   启动: systemctl start c-agent"
    echo "   停止: systemctl stop c-agent"
    echo "   重启: systemctl restart c-agent"
    echo "   状态: systemctl status c-agent"
    echo ""
    echo "📝 日志文件:"
    echo "   应用日志: /var/log/c-agent/"
    echo "   Nginx日志: /var/log/nginx/"
    echo "   系统日志: journalctl -u c-agent"
    echo ""
    echo "🔧 配置文件:"
    echo "   应用配置: $APP_DIR/"
    echo "   Nginx配置: $NGINX_AVAILABLE/c-agent"
    echo "   服务配置: $SYSTEMD_DIR/c-agent.service"
    echo ""
    print_success "部署完成！请访问上述地址测试应用"
}

# 主要部署流程
main() {
    echo "开始执行C-Agent服务器部署..."
    
    check_root
    update_system
    install_dependencies
    create_app_user
    setup_app_directory
    deploy_application
    setup_gunicorn
    setup_systemd_service
    setup_nginx
    setup_firewall
    start_services
    show_deployment_info
}

# 执行部署
main "$@"