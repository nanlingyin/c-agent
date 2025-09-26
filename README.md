# C-Agent 智能C语言助手 - 网络版

## 🎯 项目简介

C-Agent 是一个基于 Web 的智能 C 语言编程助手，提供 AI 聊天、语法帮助、代码查重等功能。

### ✨ 主要功能

- **🤖 AI 智能对话**: 基于 GPT-4 的编程助手，解答编程问题
- **📚 C语言帮助**: 关键字查询、语法说明、头文件介绍  
- **🔍 代码查重**: 智能代码相似度检测
- **📝 操作历史**: 完整的使用记录和日志
- **🌐 多语言支持**: 中文/英文界面切换
- **🎨 现代UI**: 响应式设计，支持深色主题

## 🚀 快速开始

### 前置要求

- Python 3.7 或更高版本
- 稳定的网络连接（用于 AI 对话功能）

### 安装运行

1. **下载项目**
   ```bash
   # 如果你有 git
   git clone <your-repo-url>
   cd c-agent

   # 或者直接下载解压到 c-agent 文件夹
   ```

2. **一键启动**
   ```bash
   python start.py
   ```
   
   脚本将自动：
   - 检查 Python 版本
   - 创建必要目录
   - 询问是否安装依赖
   - 启动 Web 服务器
   - 打开浏览器

3. **手动安装（可选）**
   ```bash
   pip install -r requirements.txt
   python app.py
   ```

4. **访问应用**
   
   打开浏览器访问: http://localhost:5000

## 📁 项目结构

```
c-agent/
├── app.py              # Flask 后端应用
├── main.py            # 原始命令行版本
├── start.py           # 启动脚本
├── requirements.txt   # 依赖包列表
├── config.json        # 配置文件（自动生成）
├── history.log        # 操作日志（自动生成）
├── templates/         # HTML 模板
│   └── index.html
├── static/           # 静态资源
│   ├── css/
│   │   └── style.css
│   └── js/
│       └── app.js
└── uploads/          # 文件上传目录（自动生成）
```

## 🔧 配置说明

### OpenAI API 配置

项目使用 OpenAI API 提供 AI 对话功能。需要在 `app.py` 中配置：

```python
client = OpenAI(
    api_key="your-api-key-here",  # 替换为你的 API Key
    base_url="your-base-url-here" # 替换为你的 API 端点
)
```

### 支持的文件格式

代码查重功能支持以下文件格式：
- `.c` - C 语言源代码文件
- `.txt` - 纯文本文件

## 💡 使用说明

### 1. AI 聊天
- 在聊天界面输入编程相关问题
- 支持代码块语法高亮
- 保持对话历史记录
- 支持快捷键 Enter 发送消息

### 2. C语言帮助
- 输入关键字查询语法说明
- 支持完整语句解析
- 显示所有相关关键字解释
- 支持中英文说明

### 3. 代码查重  
- 上传两个 C 代码文件
- 自动计算相似度百分比
- 使用余弦相似度算法
- 考虑关键字权重

### 4. 历史记录
- 查看所有操作记录
- 自动记录用户行为
- 支持历史记录刷新

### 5. 设置选项
- 界面语言切换（中文/英文）
- 主题切换（浅色/深色）
- 配置持久化保存

## ⌨️ 快捷键

- `Ctrl/Cmd + 1-5`: 切换到对应标签页
- `Enter`: 发送聊天消息（Shift+Enter 换行）
- `Enter`: 执行帮助搜索

## 🎨 界面特色

### 响应式设计
- 适配桌面、平板、手机
- 流畅的动画效果
- 现代化卡片式布局

### 主题支持
- 浅色主题：简洁明亮
- 深色主题：护眼舒适
- 主题设置持久化

### 交互优化
- 实时状态反馈
- 优雅的加载动画
- 友好的错误提示
- 智能表单验证

## 🔒 安全说明

- 上传的文件仅用于相似度计算
- 不会永久存储用户文件
- API 密钥请妥善保管
- 建议在内网环境使用

## 🐛 问题排查

### 常见问题

1. **依赖安装失败**
   ```bash
   # 升级 pip
   python -m pip install --upgrade pip
   
   # 使用镜像源
   pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple/
   ```

2. **端口被占用**
   ```bash
   # 修改 app.py 中的端口号
   app.run(debug=True, host='0.0.0.0', port=5001)  # 改为其他端口
   ```

3. **AI 对话失败**
   - 检查 API 密钥是否正确
   - 确认网络连接是否正常
   - 验证 API 端点地址

4. **文件上传失败**
   - 确认文件格式正确（.c 或 .txt）
   - 检查文件大小是否合理
   - 验证 uploads 目录权限

### 日志调试

查看详细错误信息：
```bash
# 启用调试模式
python app.py

# 或查看日志文件
cat history.log
```

## 🚀 部署建议

### 生产环境部署

1. **使用 Gunicorn**
   ```bash
   pip install gunicorn
   gunicorn -w 4 -b 0.0.0.0:5000 app:app
   ```

2. **使用 Docker**
   ```dockerfile
   FROM python:3.9-slim
   WORKDIR /app
   COPY requirements.txt .
   RUN pip install -r requirements.txt
   COPY . .
   EXPOSE 5000
   CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:app"]
   ```

3. **反向代理**
   - 使用 Nginx 作为反向代理
   - 配置 SSL 证书
   - 限制上传文件大小

## 📝 更新日志

### v2.0.0 (当前版本)
- ✅ 全新 Web 界面
- ✅ 响应式设计
- ✅ 多语言支持
- ✅ 主题切换
- ✅ 优化用户体验

### v1.0.0 (原始版本)
- ✅ 命令行界面
- ✅ 基础功能实现

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目采用 MIT 许可证。

## 👥 联系

如有问题，请通过以下方式联系：
- 创建 Issue
- 发送邮件
- 项目讨论区

---

**感谢使用 C-Agent！让编程学习更简单 🎉**