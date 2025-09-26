#!/bin/bash
# C-Agent 项目上传脚本
# Upload Script for C-Agent Project

echo "🚀 C-Agent 项目上传工具"
echo "========================"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查必要文件
check_files() {
    echo -e "${BLUE}检查项目文件...${NC}"
    
    required_files=("app.py" "requirements.txt" "deploy.sh")
    missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -ne 0 ]; then
        echo -e "${RED}缺少必要文件: ${missing_files[*]}${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ 项目文件检查完成${NC}"
}

# 获取服务器信息
get_server_info() {
    echo -e "${BLUE}请输入服务器信息:${NC}"
    
    read -p "服务器IP地址: " SERVER_IP
    read -p "SSH用户名 (通常是root或ubuntu): " SSH_USER
    read -p "SSH端口 (默认22): " SSH_PORT
    SSH_PORT=${SSH_PORT:-22}
    
    # 检查私钥文件
    if [ -f "Feng.pem" ]; then
        echo -e "${GREEN}✓ 找到私钥文件: Feng.pem${NC}"
        SSH_KEY="Feng.pem"
        
        # 设置私钥文件权限
        chmod 600 "$SSH_KEY"
        echo -e "${GREEN}✓ 私钥文件权限已设置${NC}"
    else
        echo -e "${RED}✗ 未找到私钥文件 Feng.pem${NC}"
        echo "请确保 Feng.pem 文件在当前目录中"
        exit 1
    fi
    
    echo -e "${GREEN}服务器信息:${NC}"
    echo "  IP: $SERVER_IP"
    echo "  用户: $SSH_USER"
    echo "  端口: $SSH_PORT"
    echo "  私钥: $SSH_KEY"
}

# 测试SSH连接
test_connection() {
    echo -e "${BLUE}测试SSH连接...${NC}"
    
    if ssh -i "$SSH_KEY" -p $SSH_PORT -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no $SSH_USER@$SERVER_IP exit 2>/dev/null; then
        echo -e "${GREEN}✓ SSH连接成功${NC}"
    else
        echo -e "${RED}✗ SSH连接失败${NC}"
        echo "请检查:"
        echo "1. 服务器IP地址是否正确: $SERVER_IP"
        echo "2. SSH用户名是否正确: $SSH_USER"
        echo "3. 私钥文件是否正确: $SSH_KEY"
        echo "4. 服务器是否开启SSH服务"
        echo "5. 防火墙是否允许SSH连接"
        
        echo -e "${YELLOW}尝试手动连接测试:${NC}"
        echo "ssh -i $SSH_KEY -p $SSH_PORT $SSH_USER@$SERVER_IP"
        exit 1
    fi
}

# 创建上传包
create_package() {
    echo -e "${BLUE}创建上传包...${NC}"
    
    PACKAGE_NAME="c-agent-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    # 排除不需要的文件
    tar --exclude='.git' \
        --exclude='__pycache__' \
        --exclude='*.pyc' \
        --exclude='.vscode' \
        --exclude='node_modules' \
        --exclude='uploads/*' \
        --exclude='history.log' \
        --exclude='Feng.pem' \
        -czf $PACKAGE_NAME *
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 上传包创建成功: $PACKAGE_NAME${NC}"
        echo "  大小: $(du -h $PACKAGE_NAME | cut -f1)"
    else
        echo -e "${RED}✗ 上传包创建失败${NC}"
        exit 1
    fi
}

# 上传文件
upload_files() {
    echo -e "${BLUE}上传文件到服务器...${NC}"
    
    # 创建临时目录
    ssh -i "$SSH_KEY" -p $SSH_PORT $SSH_USER@$SERVER_IP "mkdir -p /tmp/c-agent-upload"
    
    # 上传文件
    if scp -i "$SSH_KEY" -P $SSH_PORT $PACKAGE_NAME $SSH_USER@$SERVER_IP:/tmp/; then
        echo -e "${GREEN}✓ 文件上传成功${NC}"
        
        # 解压文件
        echo -e "${BLUE}解压文件...${NC}"
        ssh -i "$SSH_KEY" -p $SSH_PORT $SSH_USER@$SERVER_IP "
            cd /tmp && 
            tar -xzf $PACKAGE_NAME && 
            rm -rf /tmp/c-agent-upload/* &&
            mv * /tmp/c-agent-upload/ 2>/dev/null || true
        "
        
        echo -e "${GREEN}✓ 文件解压完成${NC}"
        
        # 清理本地文件
        rm $PACKAGE_NAME
        
    else
        echo -e "${RED}✗ 文件上传失败${NC}"
        rm $PACKAGE_NAME
        exit 1
    fi
}

# 准备部署
prepare_deployment() {
    echo -e "${BLUE}准备部署环境...${NC}"
    
    ssh -i "$SSH_KEY" -p $SSH_PORT $SSH_USER@$SERVER_IP "
        # 备份现有版本
        sudo rm -rf /opt/c-agent.backup 2>/dev/null || true
        sudo mv /opt/c-agent /opt/c-agent.backup 2>/dev/null || true
        
        # 移动新文件到目标位置
        sudo mv /tmp/c-agent-upload /opt/c-agent
        sudo chmod +x /opt/c-agent/deploy.sh
        sudo chmod +x /opt/c-agent/upload.sh
        
        echo '✓ 文件已移动到 /opt/c-agent'
        echo '✓ 部署脚本已设置执行权限'
    "
    
    echo -e "${GREEN}✓ 部署准备完成${NC}"
}

# 显示部署说明
show_deployment_instructions() {
    echo ""
    echo -e "${GREEN}🎉 文件上传完成！${NC}"
    echo "=========================="
    echo ""
    echo -e "${YELLOW}下一步操作:${NC}"
    echo "1. 连接到服务器:"
    echo "   ssh -i $SSH_KEY -p $SSH_PORT $SSH_USER@$SERVER_IP"
    echo ""
    echo "2. 执行部署脚本:"
    echo "   cd /opt/c-agent"
    echo "   sudo bash deploy.sh"
    echo ""
    echo "3. 部署完成后访问:"
    echo "   http://$SERVER_IP"
    echo ""
    echo -e "${BLUE}其他有用命令:${NC}"
    echo "• 查看部署状态: sudo systemctl status c-agent"
    echo "• 查看应用日志: sudo journalctl -u c-agent -f"
    echo "• 重启应用: sudo systemctl restart c-agent"
    echo ""
    echo -e "${YELLOW}快速部署命令 (可直接复制执行):${NC}"
    echo "ssh -i $SSH_KEY -p $SSH_PORT $SSH_USER@$SERVER_IP 'cd /opt/c-agent && sudo bash deploy.sh'"
    echo ""
    echo -e "${YELLOW}如果需要回滚:${NC}"
    echo "ssh -i $SSH_KEY -p $SSH_PORT $SSH_USER@$SERVER_IP 'sudo mv /opt/c-agent.backup /opt/c-agent'"
}

# 主函数
main() {
    echo "开始上传 C-Agent 项目到服务器..."
    echo ""
    
    check_files
    get_server_info
    test_connection
    create_package
    upload_files
    prepare_deployment
    show_deployment_instructions
}

# 执行主函数
main "$@"