# 🚀 快速启动指南

## 方法一：一键启动（推荐）

### Windows用户
1. 双击 `启动C-Agent.bat` 文件
2. 按照提示完成环境配置
3. 浏览器会自动打开项目

### 所有系统
```bash
python setup.py
```

## 方法二：手动配置

### 1. 安装Python
- 下载：https://www.python.org/downloads/
- ⚠️ 安装时必须勾选 "Add Python to PATH"

### 2. 验证安装
```cmd
python --version
pip --version
```

### 3. 安装依赖
```cmd
pip install -r requirements.txt
```

### 4. 配置API（重要！）
编辑 `app.py`，修改：
```python
client = OpenAI(
    api_key="your-api-key-here",  # 🔑 替换为你的API密钥
    base_url="https://api.openai.com/v1"
)
```

### 5. 启动项目
```cmd
python start.py
```

## 🔧 解决常见问题

### Python命令不存在
重新安装Python，确保勾选"Add to PATH"

### 依赖安装失败
```cmd
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple/
```

### 端口被占用
修改 `app.py` 中的端口号

## 📞 需要帮助？
运行环境配置助手：
```cmd
python setup.py
```

配置完成后访问：http://localhost:5000