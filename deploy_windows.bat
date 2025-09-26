@echo off
chcp 65001 >nul
echo 🚀 C-Agent 服务器部署工具 (Windows)
echo ====================================
echo.

:: 检查必要文件
echo 检查必要文件...
if not exist "app.py" (
    echo ❌ 缺少 app.py 文件
    pause
    exit /b 1
)
if not exist "requirements.txt" (
    echo ❌ 缺少 requirements.txt 文件
    pause
    exit /b 1
)
if not exist "deploy.sh" (
    echo ❌ 缺少 deploy.sh 文件
    pause
    exit /b 1
)
if not exist "Feng.pem" (
    echo ❌ 缺少 Feng.pem 私钥文件
    pause
    exit /b 1
)
echo ✅ 项目文件检查完成
echo.

:: 获取服务器信息
set /p SERVER_IP=请输入服务器IP地址: 
set /p SSH_USER=请输入SSH用户名 (通常是root或ubuntu): 
set /p SSH_PORT=请输入SSH端口 (默认22): 
if "%SSH_PORT%"=="" set SSH_PORT=22

echo.
echo 服务器信息:
echo   IP: %SERVER_IP%
echo   用户: %SSH_USER%
echo   端口: %SSH_PORT%
echo   私钥: Feng.pem
echo.

:: 检查是否安装了WSL或Git Bash
where bash >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✅ 找到 Bash 环境，使用 upload.sh 脚本
    echo.
    echo 开始上传项目文件...
    bash upload.sh
) else (
    echo ⚠️  未找到 Bash 环境
    echo.
    echo 请选择部署方式:
    echo 1. 安装 WSL 或 Git Bash 后使用自动脚本
    echo 2. 手动部署 (需要手动操作)
    echo.
    set /p CHOICE=请选择 (1 或 2): 
    
    if "%CHOICE%"=="1" (
        echo.
        echo 📋 安装 WSL 的步骤:
        echo 1. 以管理员身份运行 PowerShell
        echo 2. 执行: wsl --install
        echo 3. 重启电脑
        echo 4. 重新运行此脚本
        echo.
        echo 📋 或者安装 Git Bash:
        echo 1. 下载 Git for Windows: https://git-scm.com/download/win
        echo 2. 安装时选择 "Git Bash Here"
        echo 3. 重新运行此脚本
        pause
        exit /b 1
    ) else (
        call :manual_deploy
    )
)
goto :eof

:manual_deploy
echo.
echo 📋 手动部署步骤:
echo ================
echo.
echo 1. 上传文件到服务器:
echo    使用 WinSCP、FileZilla 或其他 SFTP 工具
echo    连接信息:
echo      主机: %SERVER_IP%
echo      端口: %SSH_PORT%
echo      用户名: %SSH_USER%
echo      私钥文件: %CD%\Feng.pem
echo.
echo 2. 将项目文件上传到服务器的 /tmp/c-agent-upload/ 目录
echo.
echo 3. 使用 SSH 客户端连接到服务器:
echo    推荐使用 PuTTY 或 Windows Terminal
echo    连接命令示例:
echo    ssh -i Feng.pem -p %SSH_PORT% %SSH_USER%@%SERVER_IP%
echo.
echo 4. 在服务器上执行以下命令:
echo    sudo mv /tmp/c-agent-upload /opt/c-agent
echo    cd /opt/c-agent
echo    sudo chmod +x deploy.sh
echo    sudo bash deploy.sh
echo.
echo 5. 部署完成后访问: http://%SERVER_IP%
echo.
echo 💡 建议安装 WSL 或 Git Bash 以便使用自动化脚本
echo.

:: 创建连接命令文件
echo @echo off > connect_server.bat
echo echo 连接到服务器... >> connect_server.bat
echo ssh -i Feng.pem -p %SSH_PORT% %SSH_USER%@%SERVER_IP% >> connect_server.bat
echo ✅ 已创建 connect_server.bat 文件，双击可直接连接服务器

echo.
pause
goto :eof