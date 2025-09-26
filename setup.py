#!/usr/bin/env python
"""
环境配置检测和自动安装脚本
Environment Setup and Auto-Installation Script
"""

import os
import sys
import subprocess
import platform
import webbrowser
from pathlib import Path

def print_header():
    """打印欢迎信息"""
    print("=" * 60)
    print("🚀 C-Agent 环境配置助手")
    print("   Environment Setup Assistant")
    print("=" * 60)
    print()

def check_python():
    """检查Python版本"""
    print("🔍 检查Python环境...")
    
    version = sys.version_info
    if version.major == 3 and version.minor >= 7:
        print(f"✅ Python {version.major}.{version.minor}.{version.micro} - 版本符合要求")
        return True
    else:
        print(f"❌ Python {version.major}.{version.minor}.{version.micro} - 版本过低")
        print("   需要 Python 3.7 或更高版本")
        return False

def check_pip():
    """检查pip是否可用"""
    print("🔍 检查pip包管理器...")
    try:
        import pip
        result = subprocess.run([sys.executable, "-m", "pip", "--version"], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ pip 可用: {result.stdout.strip()}")
            return True
    except:
        pass
    
    print("❌ pip 不可用")
    return False

def install_dependencies():
    """安装项目依赖"""
    print("\n📦 安装项目依赖...")
    
    requirements_file = Path("requirements.txt")
    if not requirements_file.exists():
        print("❌ 未找到 requirements.txt 文件")
        return False
    
    try:
        # 尝试使用清华镜像源
        print("   使用清华大学镜像源加速下载...")
        result = subprocess.run([
            sys.executable, "-m", "pip", "install", "-r", "requirements.txt",
            "-i", "https://pypi.tuna.tsinghua.edu.cn/simple/"
        ], check=True)
        
        print("✅ 依赖安装成功")
        return True
        
    except subprocess.CalledProcessError:
        print("⚠️  镜像源安装失败，尝试官方源...")
        try:
            result = subprocess.run([
                sys.executable, "-m", "pip", "install", "-r", "requirements.txt"
            ], check=True)
            
            print("✅ 依赖安装成功")
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"❌ 依赖安装失败: {e}")
            return False

def check_files():
    """检查必要文件是否存在"""
    print("\n📁 检查项目文件...")
    
    required_files = [
        "app.py",
        "templates/index.html",
        "static/css/style.css",
        "static/js/app.js",
        "requirements.txt"
    ]
    
    missing_files = []
    for file_path in required_files:
        if Path(file_path).exists():
            print(f"✅ {file_path}")
        else:
            print(f"❌ {file_path} - 文件缺失")
            missing_files.append(file_path)
    
    return len(missing_files) == 0

def create_directories():
    """创建必要目录"""
    print("\n📂 创建必要目录...")
    
    directories = ["uploads", "static/css", "static/js", "templates"]
    for directory in directories:
        Path(directory).mkdir(parents=True, exist_ok=True)
        print(f"✅ {directory}/")

def check_config():
    """检查配置文件"""
    print("\n⚙️ 检查配置文件...")
    
    config_file = Path("config.json")
    if not config_file.exists():
        print("   创建默认配置文件...")
        import json
        default_config = {
            "language": "zh-cn"
        }
        with open(config_file, 'w', encoding='utf-8') as f:
            json.dump(default_config, f, ensure_ascii=False, indent=4)
        print("✅ config.json 已创建")
    else:
        print("✅ config.json 已存在")

def test_imports():
    """测试关键模块导入"""
    print("\n🧪 测试模块导入...")
    
    modules = [
        ("flask", "Flask Web框架"),
        ("openai", "OpenAI API客户端"),
        ("werkzeug", "Werkzeug工具库"),
        ("colorama", "彩色终端输出")
    ]
    
    all_good = True
    for module_name, description in modules:
        try:
            __import__(module_name)
            print(f"✅ {module_name} - {description}")
        except ImportError:
            print(f"❌ {module_name} - 导入失败")
            all_good = False
    
    return all_good

def show_api_config_guide():
    """显示API配置指导"""
    print("\n🔑 OpenAI API 配置指导")
    print("=" * 40)
    print("1. 访问: https://platform.openai.com/api-keys")
    print("2. 登录并创建新的API密钥")
    print("3. 编辑 app.py 文件，找到以下代码:")
    print()
    print("   client = OpenAI(")
    print('       api_key="your-api-key-here",')
    print('       base_url="https://api.openai.com/v1"')
    print("   )")
    print()
    print("4. 将 your-api-key-here 替换为你的实际API密钥")
    print()
    
    answer = input("是否已配置API密钥？(y/n): ").lower()
    return answer in ['y', 'yes', '是']

def launch_application():
    """启动应用"""
    print("\n🚀 启动 C-Agent...")
    print("   服务器地址: http://localhost:5000")
    print("   按 Ctrl+C 停止服务器")
    print("=" * 40)
    
    try:
        # 延迟打开浏览器
        import threading
        import time
        
        def open_browser():
            time.sleep(3)
            webbrowser.open("http://localhost:5000")
        
        browser_thread = threading.Thread(target=open_browser)
        browser_thread.daemon = True
        browser_thread.start()
        
        # 启动Flask应用
        from app import app
        app.run(debug=False, host='0.0.0.0', port=5000)
        
    except KeyboardInterrupt:
        print("\n\n✅ 服务器已停止")
    except Exception as e:
        print(f"\n❌ 启动失败: {e}")
        return False
    
    return True

def main():
    """主函数"""
    print_header()
    
    # 检查Python版本
    if not check_python():
        print("\n❌ Python版本不符合要求，请安装Python 3.7+")
        input("按Enter键退出...")
        return
    
    # 检查pip
    if not check_pip():
        print("\n❌ pip不可用，请重新安装Python并确保包含pip")
        input("按Enter键退出...")
        return
    
    # 创建目录
    create_directories()
    
    # 检查文件
    if not check_files():
        print("\n❌ 项目文件不完整，请检查项目结构")
        input("按Enter键退出...")
        return
    
    # 询问是否安装依赖
    while True:
        install_deps = input("\n是否安装/更新依赖包？(y/n): ").lower()
        if install_deps in ['y', 'yes', 'n', 'no', '是', '否']:
            break
        print("请输入 y 或 n")
    
    if install_deps in ['y', 'yes', '是']:
        if not install_dependencies():
            print("\n❌ 依赖安装失败，请手动运行:")
            print("   pip install -r requirements.txt")
            input("按Enter键退出...")
            return
    
    # 测试模块导入
    if not test_imports():
        print("\n❌ 模块导入测试失败，请检查依赖安装")
        input("按Enter键退出...")
        return
    
    # 检查配置
    check_config()
    
    # API配置指导
    api_configured = show_api_config_guide()
    if not api_configured:
        print("\n⚠️ 请先配置API密钥，然后重新运行此脚本")
        input("按Enter键退出...")
        return
    
    print("\n" + "="*60)
    print("🎉 环境配置完成！")
    print("✅ Python环境正常")
    print("✅ 依赖包已安装")
    print("✅ 项目文件完整")
    print("✅ API已配置")
    print("="*60)
    
    start_app = input("\n是否立即启动应用？(y/n): ").lower()
    if start_app in ['y', 'yes', '是']:
        launch_application()
    else:
        print("\n您可以随时运行以下命令启动应用:")
        print("  python app.py")
        print("  或")
        print("  python start.py")

if __name__ == "__main__":
    main()