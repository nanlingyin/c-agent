# C-Agent PowerShell 部署脚本
# PowerShell Deployment Script for C-Agent

param(
    [string]$ServerIP,
    [string]$Username = "root",
    [int]$Port = 22
)

Write-Host "🚀 C-Agent PowerShell 部署工具" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host ""

# 检查必要文件
Write-Host "检查必要文件..." -ForegroundColor Blue
$requiredFiles = @("app.py", "requirements.txt", "deploy.sh", "Feng.pem")
$missingFiles = @()

foreach ($file in $requiredFiles) {
    if (!(Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "❌ 缺少必要文件: $($missingFiles -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host "✅ 项目文件检查完成" -ForegroundColor Green
Write-Host ""

# 获取服务器信息（如果未通过参数提供）
if ([string]::IsNullOrEmpty($ServerIP)) {
    $ServerIP = Read-Host "请输入服务器IP地址"
}
if ([string]::IsNullOrEmpty($Username)) {
    $Username = Read-Host "请输入SSH用户名 (默认: root)"
    if ([string]::IsNullOrEmpty($Username)) { $Username = "root" }
}
if ($Port -eq 0) {
    $portInput = Read-Host "请输入SSH端口 (默认: 22)"
    if ([string]::IsNullOrEmpty($portInput)) { $Port = 22 } else { $Port = [int]$portInput }
}

Write-Host "服务器信息:" -ForegroundColor Green
Write-Host "  IP: $ServerIP"
Write-Host "  用户: $Username"  
Write-Host "  端口: $Port"
Write-Host "  私钥: Feng.pem"
Write-Host ""

# 检查SSH客户端
$sshAvailable = $false
try {
    $sshVersion = ssh -V 2>&1
    $sshAvailable = $true
    Write-Host "✅ SSH客户端可用: $sshVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ SSH客户端不可用" -ForegroundColor Red
}

# 检查SCP
$scpAvailable = $false
try {
    scp 2>&1 | Out-Null
    $scpAvailable = $true
    Write-Host "✅ SCP可用" -ForegroundColor Green
} catch {
    Write-Host "❌ SCP不可用" -ForegroundColor Red
}

if (!$sshAvailable -or !$scpAvailable) {
    Write-Host ""
    Write-Host "⚠️  SSH/SCP 工具不可用，请选择以下选项:" -ForegroundColor Yellow
    Write-Host "1. 安装 OpenSSH (推荐)"
    Write-Host "2. 安装 Git for Windows"
    Write-Host "3. 手动部署"
    Write-Host ""
    
    $choice = Read-Host "请选择 (1-3)"
    
    switch ($choice) {
        "1" {
            Write-Host "安装 OpenSSH 的步骤:" -ForegroundColor Cyan
            Write-Host "1. 以管理员身份运行 PowerShell"
            Write-Host "2. 执行: Add-WindowsCapability -Online -Name OpenSSH.Client"
            Write-Host "3. 重新运行此脚本"
            exit
        }
        "2" {
            Write-Host "安装 Git for Windows:" -ForegroundColor Cyan
            Write-Host "1. 访问: https://git-scm.com/download/win"
            Write-Host "2. 下载并安装 Git for Windows"
            Write-Host "3. 安装后重新运行此脚本"
            exit
        }
        "3" {
            Show-ManualDeployment -ServerIP $ServerIP -Username $Username -Port $Port
            return
        }
        default {
            Write-Host "无效选择，退出" -ForegroundColor Red
            exit
        }
    }
}

# 设置私钥文件权限
try {
    icacls "Feng.pem" /inheritance:r /grant:r "$($env:USERNAME):F" | Out-Null
    Write-Host "✅ 私钥文件权限已设置" -ForegroundColor Green
} catch {
    Write-Host "⚠️  设置私钥权限失败，继续尝试..." -ForegroundColor Yellow
}

# 测试SSH连接
Write-Host "测试SSH连接..." -ForegroundColor Blue
try {
    $sshTest = ssh -i "Feng.pem" -p $Port -o "ConnectTimeout=10" -o "BatchMode=yes" -o "StrictHostKeyChecking=no" "$Username@$ServerIP" "echo 'SSH连接测试成功'" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ SSH连接成功" -ForegroundColor Green
    } else {
        throw "SSH连接失败"
    }
} catch {
    Write-Host "❌ SSH连接失败" -ForegroundColor Red
    Write-Host "请检查:" -ForegroundColor Yellow
    Write-Host "1. 服务器IP地址: $ServerIP"
    Write-Host "2. SSH用户名: $Username"
    Write-Host "3. 私钥文件: Feng.pem"
    Write-Host "4. 服务器SSH服务状态"
    Write-Host ""
    Write-Host "手动测试命令:" -ForegroundColor Cyan
    Write-Host "ssh -i Feng.pem -p $Port $Username@$ServerIP"
    exit 1
}

# 创建上传包
Write-Host "创建上传包..." -ForegroundColor Blue
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$packageName = "c-agent-$timestamp.tar.gz"

# 使用PowerShell压缩（如果tar不可用）
try {
    # 尝试使用tar（Windows 10 1803+自带）
    tar --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' --exclude='.vscode' --exclude='node_modules' --exclude='uploads/*' --exclude='history.log' --exclude='Feng.pem' -czf $packageName *
    Write-Host "✅ 上传包创建成功: $packageName" -ForegroundColor Green
} catch {
    Write-Host "⚠️  tar命令不可用，使用ZIP压缩..." -ForegroundColor Yellow
    $packageName = "c-agent-$timestamp.zip"
    
    # 创建临时目录
    $tempDir = "c-agent-temp"
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    
    # 复制文件（排除不需要的）
    $excludePatterns = @('.git', '__pycache__', '*.pyc', '.vscode', 'node_modules', 'history.log', 'Feng.pem')
    Get-ChildItem -Path . -Recurse | Where-Object {
        $item = $_
        $shouldExclude = $false
        foreach ($pattern in $excludePatterns) {
            if ($item.Name -like $pattern -or $item.FullName -like "*$pattern*") {
                $shouldExclude = $true
                break
            }
        }
        !$shouldExclude
    } | ForEach-Object {
        $relativePath = $_.FullName.Substring((Get-Location).Path.Length + 1)
        $destPath = Join-Path $tempDir $relativePath
        $destDir = Split-Path $destPath -Parent
        if (!(Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Copy-Item $_.FullName $destPath
    }
    
    Compress-Archive -Path "$tempDir\*" -DestinationPath $packageName
    Remove-Item $tempDir -Recurse -Force
    Write-Host "✅ 上传包创建成功: $packageName" -ForegroundColor Green
}

# 上传文件
Write-Host "上传文件到服务器..." -ForegroundColor Blue
try {
    # 创建临时目录
    ssh -i "Feng.pem" -p $Port "$Username@$ServerIP" "mkdir -p /tmp/c-agent-upload"
    
    # 上传文件
    scp -i "Feng.pem" -P $Port $packageName "$Username@$ServerIP":/tmp/
    
    # 解压文件
    if ($packageName.EndsWith('.zip')) {
        ssh -i "Feng.pem" -p $Port "$Username@$ServerIP" "cd /tmp && unzip -o $packageName && rm -rf /tmp/c-agent-upload/* && mv * /tmp/c-agent-upload/ 2>/dev/null || true"
    } else {
        ssh -i "Feng.pem" -p $Port "$Username@$ServerIP" "cd /tmp && tar -xzf $packageName && rm -rf /tmp/c-agent-upload/* && mv * /tmp/c-agent-upload/ 2>/dev/null || true"
    }
    
    Write-Host "✅ 文件上传成功" -ForegroundColor Green
    
    # 清理本地文件
    Remove-Item $packageName
} catch {
    Write-Host "❌ 文件上传失败: $($_.Exception.Message)" -ForegroundColor Red
    if (Test-Path $packageName) { Remove-Item $packageName }
    exit 1
}

# 准备部署
Write-Host "准备部署环境..." -ForegroundColor Blue
try {
    ssh -i "Feng.pem" -p $Port "$Username@$ServerIP" @"
        sudo rm -rf /opt/c-agent.backup 2>/dev/null || true
        sudo mv /opt/c-agent /opt/c-agent.backup 2>/dev/null || true
        sudo mv /tmp/c-agent-upload /opt/c-agent
        sudo chmod +x /opt/c-agent/deploy.sh
        sudo chmod +x /opt/c-agent/upload.sh
"@
    Write-Host "✅ 部署准备完成" -ForegroundColor Green
} catch {
    Write-Host "❌ 部署准备失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 显示部署说明
Write-Host ""
Write-Host "🎉 文件上传完成！" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host ""
Write-Host "下一步操作:" -ForegroundColor Yellow
Write-Host "1. 连接到服务器并执行部署:"
Write-Host "   ssh -i Feng.pem -p $Port $Username@$ServerIP" -ForegroundColor Cyan
Write-Host "   cd /opt/c-agent && sudo bash deploy.sh" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. 或者使用一键部署命令:" -ForegroundColor Yellow
Write-Host "   ssh -i Feng.pem -p $Port $Username@$ServerIP 'cd /opt/c-agent && sudo bash deploy.sh'" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. 部署完成后访问:" -ForegroundColor Yellow
Write-Host "   http://$ServerIP" -ForegroundColor Cyan
Write-Host ""

# 询问是否立即执行部署
$deploy = Read-Host "是否立即执行部署? (y/N)"
if ($deploy -eq 'y' -or $deploy -eq 'Y') {
    Write-Host "执行自动部署..." -ForegroundColor Blue
    try {
        ssh -i "Feng.pem" -p $Port "$Username@$ServerIP" "cd /opt/c-agent && sudo bash deploy.sh"
        Write-Host ""
        Write-Host "🎉 部署完成！访问地址: http://$ServerIP" -ForegroundColor Green
    } catch {
        Write-Host "❌ 自动部署失败，请手动执行部署命令" -ForegroundColor Red
    }
}

function Show-ManualDeployment {
    param($ServerIP, $Username, $Port)
    
    Write-Host ""
    Write-Host "📋 手动部署步骤:" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. 使用SFTP工具上传文件:"
    Write-Host "   推荐工具: WinSCP, FileZilla"
    Write-Host "   连接信息:"
    Write-Host "     主机: $ServerIP"
    Write-Host "     端口: $Port"
    Write-Host "     用户名: $Username"
    Write-Host "     私钥文件: $PWD\Feng.pem"
    Write-Host ""
    Write-Host "2. 上传所有项目文件到服务器 /tmp/c-agent-upload/ 目录"
    Write-Host ""
    Write-Host "3. 使用SSH客户端连接服务器并执行:"
    Write-Host "   sudo mv /tmp/c-agent-upload /opt/c-agent"
    Write-Host "   cd /opt/c-agent"
    Write-Host "   sudo chmod +x deploy.sh"
    Write-Host "   sudo bash deploy.sh"
    Write-Host ""
    Write-Host "4. 访问: http://$ServerIP"
}