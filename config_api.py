#!/usr/bin/env python
"""
OpenAI API 配置助手
OpenAI API Configuration Helper
"""

import os
import re
from pathlib import Path

def print_banner():
    """打印横幅"""
    print("=" * 60)
    print("🔑 OpenAI API 配置助手")
    print("   OpenAI API Configuration Helper")
    print("=" * 60)
    print()

def get_current_config():
    """获取当前配置"""
    app_file = Path("app.py")
    if not app_file.exists():
        return None, None
    
    with open(app_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 查找API密钥
    api_key_match = re.search(r'api_key="([^"]+)"', content)
    base_url_match = re.search(r'base_url="([^"]+)"', content)
    
    current_key = api_key_match.group(1) if api_key_match else None
    current_url = base_url_match.group(1) if base_url_match else None
    
    return current_key, current_url

def update_config(new_api_key, new_base_url):
    """更新配置"""
    app_file = Path("app.py")
    
    with open(app_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 替换API密钥
    content = re.sub(
        r'api_key="[^"]*"',
        f'api_key="{new_api_key}"',
        content
    )
    
    # 替换base_url
    content = re.sub(
        r'base_url="[^"]*"',
        f'base_url="{new_base_url}"',
        content
    )
    
    with open(app_file, 'w', encoding='utf-8') as f:
        f.write(content)

def main():
    """主函数"""
    print_banner()
    
    # 获取当前配置
    current_key, current_url = get_current_config()
    
    if current_key:
        # 隐藏部分密钥用于显示
        masked_key = current_key[:8] + "..." + current_key[-4:] if len(current_key) > 12 else current_key
        print(f"📋 当前API密钥: {masked_key}")
        print(f"🌐 当前API端点: {current_url}")
        print()
    
    # 显示获取API密钥的方法
    print("🔑 如何获取OpenAI API密钥:")
    print("1. 访问: https://platform.openai.com/")
    print("2. 登录或注册账户")
    print("3. 进入 API Keys 页面")
    print("4. 点击 'Create new secret key'")
    print("5. 复制生成的密钥")
    print()
    
    print("🌍 API端点选择:")
    print("1. 官方地址: https://api.openai.com/v1")
    print("2. 第三方代理: 如 https://api.ephone.chat/v1")
    print("3. 自建代理: 根据你的配置")
    print()
    
    # 询问是否要更新配置
    while True:
        update = input("是否要更新API配置？(y/n): ").lower()
        if update in ['y', 'yes', 'n', 'no', '是', '否']:
            break
        print("请输入 y 或 n")
    
    if update in ['n', 'no', '否']:
        print("配置保持不变")
        return
    
    # 输入新的API密钥
    print("\n🔑 请输入新的API密钥:")
    print("(格式通常为: sk-xxxxxxxxxx)")
    new_api_key = input("API Key: ").strip()
    
    if not new_api_key:
        print("❌ API密钥不能为空")
        return
    
    if not new_api_key.startswith('sk-'):
        print("⚠️ 警告: API密钥格式可能不正确，通常以'sk-'开头")
        continue_anyway = input("是否继续？(y/n): ").lower()
        if continue_anyway not in ['y', 'yes', '是']:
            return
    
    # 选择API端点
    print("\n🌐 请选择API端点:")
    print("1. 官方OpenAI (https://api.openai.com/v1)")
    print("2. ephone代理 (https://api.ephone.chat/v1)")
    print("3. 自定义端点")
    
    while True:
        choice = input("选择 (1/2/3): ").strip()
        if choice in ['1', '2', '3']:
            break
        print("请输入 1、2 或 3")
    
    if choice == '1':
        new_base_url = "https://api.openai.com/v1"
    elif choice == '2':
        new_base_url = "https://api.ephone.chat/v1"
    else:
        new_base_url = input("请输入自定义API端点: ").strip()
        if not new_base_url.startswith('http'):
            print("❌ API端点格式不正确，应以http或https开头")
            return
    
    # 更新配置
    try:
        update_config(new_api_key, new_base_url)
        print("\n✅ API配置更新成功！")
        print(f"🔑 新API密钥: {new_api_key[:8]}...{new_api_key[-4:]}")
        print(f"🌐 新API端点: {new_base_url}")
        print()
        print("现在可以启动C-Agent了:")
        print("  python start.py")
        print("  或")
        print("  双击 '启动C-Agent.bat'")
        
    except Exception as e:
        print(f"❌ 配置更新失败: {e}")

if __name__ == "__main__":
    main()