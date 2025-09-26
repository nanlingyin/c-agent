@echo off
chcp 65001 >nul
title C-Agent 智能C语言助手

echo.
echo ===============================================
echo         C-Agent 智能C语言助手 - 网络版
echo              Intelligent C Assistant
echo ===============================================
echo.

REM 检查Python是否安装
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ 错误: 未找到 Python
    echo.
    echo 请选择安装方式:
    echo 1. 访问官网下载: https://www.python.org/downloads/
    echo 2. 使用Microsoft Store搜索"Python"
    echo.
    echo ⚠️ 安装时请务必勾选 "Add Python to PATH"
    echo.
    set /p choice=是否已安装Python？按任意键重新检测，或输入'q'退出: 
    if /i "%choice%"=="q" goto end
    goto check_python
)

:check_python
python --version >nul 2>&1
if errorlevel 1 goto python_error

echo ✅ Python 环境检查通过
echo.

REM 检查是否为首次运行
if not exist "config.json" (
    echo 🔧 检测到首次运行，启动环境配置...
    echo.
    python setup.py
    goto end
)

REM 启动应用
echo 🚀 正在启动 C-Agent...
echo    服务器地址: http://localhost:5000
echo    按 Ctrl+C 停止服务器
echo.
echo ===============================================
echo.

python start.py
goto end

:python_error
echo ❌ Python环境异常，启动环境配置助手...
python setup.py

:end
echo.
echo 👋 感谢使用 C-Agent！
pause