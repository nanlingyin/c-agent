# 🚀 C-Agent 环境配置指南

## 📋 系统要求

- Windows 10/11
- Python 3.7 或更高版本
- 至少 500MB 可用空间
- 稳定的网络连接

## 🐍 步骤1: 安装 Python

### 方法一：官网下载（推荐）

1. **下载 Python**
   - 访问: https://www.python.org/downloads/
   - 点击 "Download Python 3.x.x"
   - 下载最新稳定版本

2. **安装 Python**
   - 运行下载的安装程序
   - ⚠️ **重要**: 勾选 "Add Python to PATH"
   - 选择 "Install Now" 或 "Customize installation"
   - 等待安装完成

3. **验证安装**
   ```cmd
   # 打开新的命令提示符或 PowerShell
   python --version
   pip --version
   ```

### 方法二：Microsoft Store

1. 打开 Microsoft Store
2. 搜索 "Python 3.9" 或 "Python 3.10"
3. 点击安装官方版本
4. 安装完成后验证

## 🔧 步骤2: 配置项目环境

### 2.1 验证 Python 安装

```powershell
# 在项目目录下运行
python --version
# 应该显示: Python 3.x.x

pip --version
# 应该显示: pip 23.x.x from ...
```

### 2.2 安装项目依赖

```powershell
# 方法1: 使用启动脚本（推荐）
python start.py

# 方法2: 手动安装
pip install -r requirements.txt
```

如果遇到网络问题，使用国内镜像：
```powershell
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple/
```

### 2.3 配置 OpenAI API

编辑 `app.py` 文件，修改以下部分：

```python
# 初始化 OpenAI 客户端
client = OpenAI(
    api_key="your-api-key-here",        # 替换为你的 API Key
    base_url="https://api.openai.com/v1" # 或其他 API 端点
)
```

**获取 API Key:**
- 访问: https://platform.openai.com/api-keys
- 登录后创建新的 API Key
- 复制 Key 到代码中

## 🚀 步骤3: 启动项目

### 方法一：使用启动脚本
```powershell
python start.py
```

### 方法二：使用批处理文件
双击 `启动C-Agent.bat` 文件

### 方法三：直接启动
```powershell
python app.py
```

成功启动后：
- 浏览器会自动打开
- 访问地址: http://localhost:5000
- 看到 C-Agent 界面表示成功

## 🛠 故障排除

### 问题1: "python" 不是内部或外部命令

**解决方法:**
1. 重新安装 Python，确保勾选 "Add to PATH"
2. 手动添加到环境变量:
   - 找到 Python 安装路径（通常在 `C:\Users\用户名\AppData\Local\Programs\Python\Python3x\`）
   - 将路径添加到系统 PATH 环境变量

### 问题2: pip 安装失败

**解决方法:**
```powershell
# 升级 pip
python -m pip install --upgrade pip

# 使用镜像源
pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple/
```

### 问题3: 端口被占用

**解决方法:**
修改 `app.py` 中的端口号：
```python
app.run(debug=True, host='0.0.0.0', port=5001)  # 改为其他端口
```

### 问题4: API 调用失败

**检查项目:**
1. API Key 是否正确
2. 网络连接是否正常
3. API 端点地址是否正确
4. 账户是否有余额

## 📁 文件结构确认

确保以下文件存在：
```
c-agent/
├── app.py              ✅ Web应用主程序
├── start.py            ✅ 启动脚本
├── requirements.txt    ✅ 依赖列表
├── 启动C-Agent.bat     ✅ Windows启动文件
├── templates/
│   └── index.html      ✅ 前端模板
├── static/
│   ├── css/style.css   ✅ 样式文件
│   └── js/app.js       ✅ JavaScript文件
└── uploads/            📁 上传目录（自动创建）
```

## 🎯 快速测试

1. **测试聊天功能**: 在聊天界面输入 "你好"
2. **测试帮助功能**: 搜索关键字 "printf"
3. **测试查重功能**: 上传 `test_file1.c` 和 `test_file2.c`
4. **测试语言切换**: 点击右上角语言按钮

## 📞 需要帮助？

如果遇到问题：
1. 检查 Python 版本是否 ≥ 3.7
2. 确认所有依赖都已安装
3. 查看终端错误信息
4. 检查防火墙设置

---

**配置完成后，你就可以享受现代化的 C-Agent Web 界面了！** 🎉