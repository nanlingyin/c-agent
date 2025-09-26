#!/usr/bin/env python
"""
C-Agent Web Application Launcher
启动 C-Agent 网络应用程序
"""

import os
import sys
import subprocess
import webbrowser
import time
from pathlib import Path

def check_python_version():
    """检查Python版本"""
    if sys.version_info < (3, 7):
        print("错误: 需要 Python 3.7 或更高版本")
        print("Error: Python 3.7 or higher is required")
        sys.exit(1)

def install_requirements():
    """安装依赖包"""
    requirements_file = Path("requirements.txt")
    if requirements_file.exists():
        print("安装依赖包... Installing dependencies...")
        try:
            subprocess.check_call([
                sys.executable, "-m", "pip", "install", "-r", "requirements.txt"
            ])
            print("✓ 依赖包安装完成 Dependencies installed successfully")
        except subprocess.CalledProcessError as e:
            print(f"✗ 安装依赖包失败 Failed to install dependencies: {e}")
            return False
    else:
        print("警告: 未找到 requirements.txt 文件")
        print("Warning: requirements.txt not found")
    return True

def create_directories():
    """创建必要的目录"""
    directories = ["uploads", "static/css", "static/js", "templates"]
    for directory in directories:
        Path(directory).mkdir(parents=True, exist_ok=True)
    print("✓ 目录创建完成 Directories created")

def check_config():
    """检查配置文件"""
    config_file = Path("config.json")
    if not config_file.exists():
        default_config = {
            "language": "zh-cn"
        }
        import json
        with open(config_file, 'w', encoding='utf-8') as f:
            json.dump(default_config, f, ensure_ascii=False, indent=4)
        print("✓ 创建默认配置文件 Default config file created")

def start_server():
    """启动Flask服务器"""
    try:
        print("\n" + "="*50)
        print("🚀 启动 C-Agent 服务器...")
        print("🚀 Starting C-Agent Server...")
        print("="*50)
        print("\n📍 服务器地址 Server URL: http://localhost:5000")
        print("🔧 按 Ctrl+C 停止服务器 Press Ctrl+C to stop server")
        print("\n" + "="*50)
        
        # 延迟打开浏览器
        def open_browser():
            time.sleep(2)
            webbrowser.open("http://localhost:5000")
        
        import threading
        browser_thread = threading.Thread(target=open_browser)
        browser_thread.daemon = True
        browser_thread.start()
        
        # 启动Flask应用
        from app import app
        app.run(debug=True, host='0.0.0.0', port=5000, use_reloader=False)
        
    except KeyboardInterrupt:
        print("\n\n✓ 服务器已停止 Server stopped")
    except Exception as e:
        print(f"\n✗ 启动服务器失败 Failed to start server: {e}")
        print("\n请检查以下问题 Please check:")
        print("1. 是否安装了所有依赖 All dependencies installed")
        print("2. 端口5000是否被占用 Port 5000 is not in use")
        print("3. OpenAI API配置是否正确 OpenAI API configuration is correct")

def main():
    """主函数"""
    print("C-Agent Web Application")
    print("智能C语言助手网络版")
    print("=" * 40)
    
    # 检查Python版本
    check_python_version()
    
    # 创建目录
    create_directories()
    
    # 检查配置
    check_config()
    
    # 询问是否安装依赖
    while True:
        install = input("\n是否安装/更新依赖包? Install/update dependencies? (y/n): ").lower()
        if install in ['y', 'yes', 'n', 'no']:
            break
        print("请输入 y 或 n Please enter y or n")
    
    if install in ['y', 'yes']:
        if not install_requirements():
            return
    
    # 启动服务器
    start_server()

if __name__ == "__main__":
    main()