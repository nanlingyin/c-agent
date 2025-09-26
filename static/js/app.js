// 应用程序主类
class CAgentApp {
    constructor() {
        this.currentLanguage = 'zh-cn';
        this.chatHistory = [];
        this.isLoading = false;
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.loadConfig();
        this.loadLanguage();
        this.initializeTabs();
    }

    // 设置事件监听器
    setupEventListeners() {
        // 导航菜单点击事件
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', (e) => {
                this.switchTab(e.currentTarget.dataset.tab);
            });
        });

        // 语言切换
        document.getElementById('languageToggle').addEventListener('click', () => {
            this.toggleLanguage();
        });

        // 聊天相关事件
        this.setupChatEvents();

        // 帮助搜索事件
        this.setupHelpEvents();

        // 相似度检测事件
        this.setupSimilarityEvents();

        // 历史记录事件
        this.setupHistoryEvents();

        // 设置事件
        this.setupSettingsEvents();

        // 通知关闭事件
        document.querySelector('.notification-close').addEventListener('click', () => {
            this.hideNotification();
        });

        // 键盘事件
        this.setupKeyboardEvents();
    }

    // 设置聊天相关事件
    setupChatEvents() {
        const chatInput = document.getElementById('chatInput');
        const sendButton = document.getElementById('sendButton');

        sendButton.addEventListener('click', () => {
            this.sendMessage();
        });

        chatInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                this.sendMessage();
            }
        });

        chatInput.addEventListener('input', () => {
            sendButton.disabled = chatInput.value.trim() === '';
        });
    }

    // 设置帮助相关事件
    setupHelpEvents() {
        const helpInput = document.getElementById('helpInput');
        const searchBtn = document.getElementById('helpSearchBtn');

        searchBtn.addEventListener('click', () => {
            this.searchHelp();
        });

        helpInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                e.preventDefault();
                this.searchHelp();
            }
        });
    }

    // 设置相似度检测事件
    setupSimilarityEvents() {
        const form = document.getElementById('similarityForm');
        const file1Input = document.getElementById('file1');
        const file2Input = document.getElementById('file2');

        form.addEventListener('submit', (e) => {
            e.preventDefault();
            this.analyzeSimilarity();
        });

        file1Input.addEventListener('change', (e) => {
            this.handleFileSelect(e.target, 'file1Info', 'code1Content', 'file1Name');
        });

        file2Input.addEventListener('change', (e) => {
            this.handleFileSelect(e.target, 'file2Info', 'code2Content', 'file2Name');
        });

        // 预览切换事件
        const togglePreviewBtn = document.getElementById('togglePreview');
        if (togglePreviewBtn) {
            togglePreviewBtn.addEventListener('click', () => {
                this.toggleCodePreview();
            });
        }
    }

    // 设置历史记录事件
    setupHistoryEvents() {
        document.getElementById('refreshHistory').addEventListener('click', () => {
            this.loadHistory();
        });
    }

    // 设置设置页面事件
    setupSettingsEvents() {
        const languageSelect = document.getElementById('languageSelect');
        const themeSelect = document.getElementById('themeSelect');

        languageSelect.addEventListener('change', (e) => {
            this.changeLanguage(e.target.value);
        });

        themeSelect.addEventListener('change', (e) => {
            this.changeTheme(e.target.value);
        });
    }

    // 设置键盘快捷键
    setupKeyboardEvents() {
        document.addEventListener('keydown', (e) => {
            // Ctrl/Cmd + 数字键切换标签页
            if ((e.ctrlKey || e.metaKey) && e.key >= '1' && e.key <= '5') {
                e.preventDefault();
                const tabIndex = parseInt(e.key) - 1;
                const tabs = ['chat', 'help', 'similarity', 'history', 'settings'];
                if (tabs[tabIndex]) {
                    this.switchTab(tabs[tabIndex]);
                }
            }
        });
    }

    // 切换标签页
    switchTab(tabName) {
        // 更新导航栏激活状态
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
        });
        document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');

        // 显示对应的内容
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.remove('active');
        });
        document.getElementById(`${tabName}-tab`).classList.add('active');

        // 特殊处理某些标签页
        if (tabName === 'history') {
            this.loadHistory();
        }
    }

    // 发送聊天消息
    async sendMessage() {
        const input = document.getElementById('chatInput');
        const message = input.value.trim();

        if (!message || this.isLoading) return;

        // 清空输入框
        input.value = '';
        document.getElementById('sendButton').disabled = true;

        // 添加用户消息到界面
        this.addMessage(message, 'user');

        // 显示加载状态
        this.showLoading();

        try {
            const response = await fetch('/api/chat', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    message: message,
                    history: this.chatHistory
                })
            });

            const data = await response.json();

            if (data.success) {
                // 添加AI回复到界面
                this.addMessage(data.response, 'assistant');
                
                // 更新聊天历史
                this.chatHistory.push(
                    { role: 'user', content: message },
                    { role: 'assistant', content: data.response }
                );

                // 限制历史记录长度
                if (this.chatHistory.length > 20) {
                    this.chatHistory = this.chatHistory.slice(-20);
                }
            } else {
                this.showNotification('聊天服务暂时不可用', 'error');
            }
        } catch (error) {
            console.error('发送消息时出错:', error);
            this.showNotification('发送消息失败，请检查网络连接', 'error');
        } finally {
            this.hideLoading();
        }
    }

    // 添加消息到聊天界面
    addMessage(content, type) {
        const messagesContainer = document.getElementById('chatMessages');
        const messageElement = document.createElement('div');
        messageElement.className = `message ${type}`;

        const avatarIcon = type === 'user' ? 'fa-user' : 'fa-robot';
        const messageHtml = `
            <div class="message-avatar">
                <i class="fas ${avatarIcon}"></i>
            </div>
            <div class="message-content">
                ${this.formatMessage(content)}
            </div>
        `;

        messageElement.innerHTML = messageHtml;
        messagesContainer.appendChild(messageElement);

        // 滚动到底部
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }

    // 格式化消息内容
    formatMessage(content) {
        // 将代码块用 <pre><code> 包装
        content = content.replace(/```(\w+)?\n([\s\S]*?)```/g, (match, lang, code) => {
            return `<pre><code class="language-${lang || 'text'}">${this.escapeHtml(code.trim())}</code></pre>`;
        });

        // 将行内代码用 <code> 包装
        content = content.replace(/`([^`]+)`/g, '<code>$1</code>');

        // 将换行转换为 <br>
        content = content.replace(/\n/g, '<br>');

        return content;
    }

    // HTML 转义
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    // 搜索帮助
    async searchHelp() {
        const input = document.getElementById('helpInput');
        const query = input.value.trim();

        if (!query) {
            this.showNotification('请输入要查询的内容', 'error');
            return;
        }

        this.showLoading();

        try {
            const response = await fetch('/api/help', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    query: query,
                    language: this.currentLanguage
                })
            });

            const data = await response.json();

            if (data.success) {
                this.displayHelpResults(data.results, data.type);
            } else {
                this.displayNoResults(data.message || '未找到相关结果');
            }
        } catch (error) {
            console.error('搜索帮助时出错:', error);
            this.showNotification('搜索失败，请重试', 'error');
        } finally {
            this.hideLoading();
        }
    }

    // 显示帮助搜索结果
    displayHelpResults(results, type) {
        const resultsContainer = document.getElementById('helpResults');
        resultsContainer.innerHTML = '';

        Object.keys(results).forEach(keyword => {
            const resultElement = document.createElement('div');
            resultElement.className = 'keyword-result';
            resultElement.innerHTML = `
                <div class="keyword-name">${keyword}</div>
                <div class="keyword-description">${results[keyword]}</div>
            `;
            resultsContainer.appendChild(resultElement);
        });
    }

    // 显示无结果
    displayNoResults(message) {
        const resultsContainer = document.getElementById('helpResults');
        resultsContainer.innerHTML = `
            <div class="help-placeholder">
                <i class="fas fa-exclamation-circle"></i>
                <p>${message}</p>
            </div>
        `;
    }

    // 处理文件选择
    handleFileSelect(input, infoId, contentId, nameId) {
        const file = input.files[0];
        const infoElement = document.getElementById(infoId);
        const contentElement = document.getElementById(contentId);
        const nameElement = document.getElementById(nameId);
        const uploadContainer = input.closest('.file-upload');

        if (file) {
            // 显示文件信息
            infoElement.textContent = `已选择: ${file.name} (${(file.size / 1024).toFixed(2)} KB)`;
            infoElement.style.display = 'block';

            // 添加选中状态样式
            uploadContainer.classList.add('selected');

            // 读取文件内容并显示预览
            const reader = new FileReader();
            reader.onload = (e) => {
                contentElement.textContent = e.target.result;
                nameElement.textContent = file.name;

                // 应用语法高亮
                if (typeof Prism !== 'undefined') {
                    Prism.highlightElement(contentElement);
                }

                // 检查是否两个文件都已选择，如果是则显示预览区域
                const file1 = document.getElementById('file1').files[0];
                const file2 = document.getElementById('file2').files[0];
                if (file1 && file2) {
                    this.showCodePreview();
                }
            };

            reader.onerror = () => {
                this.showNotification('文件读取失败，请重试', 'error');
            };

            reader.readAsText(file);
        } else {
            // 清除文件信息和预览
            infoElement.style.display = 'none';
            uploadContainer.classList.remove('selected');
            contentElement.textContent = '';
            nameElement.textContent = '';
            
            // 隐藏预览区域
            this.hideCodePreview();
        }

        // 检查是否两个文件都已选择，更新分析按钮状态
        const file1 = document.getElementById('file1').files[0];
        const file2 = document.getElementById('file2').files[0];
        document.getElementById('analyzeBtn').disabled = !(file1 && file2);
    }

    // 显示代码预览区域
    showCodePreview() {
        const previewSection = document.getElementById('codePreviewSection');
        const toggleBtn = document.getElementById('togglePreview');
        
        previewSection.style.display = 'block';
        
        // 更新切换按钮文本
        const buttonText = toggleBtn.querySelector('span[data-lang-key="toggle-preview"]');
        const buttonIcon = toggleBtn.querySelector('i');
        
        if (this.currentLanguage === 'zh-cn') {
            buttonText.textContent = '隐藏预览';
        } else {
            buttonText.textContent = 'Hide Preview';
        }
        buttonIcon.className = 'fas fa-eye-slash';
    }

    // 隐藏代码预览区域
    hideCodePreview() {
        const previewSection = document.getElementById('codePreviewSection');
        previewSection.style.display = 'none';
    }

    // 切换代码预览显示状态
    toggleCodePreview() {
        const previewSection = document.getElementById('codePreviewSection');
        const toggleBtn = document.getElementById('togglePreview');
        const buttonText = toggleBtn.querySelector('span[data-lang-key="toggle-preview"]');
        const buttonIcon = toggleBtn.querySelector('i');
        
        const isHidden = previewSection.style.display === 'none';
        
        if (isHidden) {
            previewSection.style.display = 'block';
            if (this.currentLanguage === 'zh-cn') {
                buttonText.textContent = '隐藏预览';
            } else {
                buttonText.textContent = 'Hide Preview';
            }
            buttonIcon.className = 'fas fa-eye-slash';
        } else {
            previewSection.style.display = 'none';
            if (this.currentLanguage === 'zh-cn') {
                buttonText.textContent = '显示预览';
            } else {
                buttonText.textContent = 'Show Preview';
            }
            buttonIcon.className = 'fas fa-eye';
        }
    }

    // 分析代码相似度
    async analyzeSimilarity() {
        const formData = new FormData();
        const file1 = document.getElementById('file1').files[0];
        const file2 = document.getElementById('file2').files[0];

        if (!file1 || !file2) {
            this.showNotification('请选择两个文件', 'error');
            return;
        }

        formData.append('file1', file1);
        formData.append('file2', file2);

        this.showLoading();

        try {
            const response = await fetch('/api/similarity', {
                method: 'POST',
                body: formData
            });

            const data = await response.json();

            if (data.success) {
                this.displaySimilarityResult(data);
            } else {
                this.showNotification(data.error || '分析失败', 'error');
            }
        } catch (error) {
            console.error('分析相似度时出错:', error);
            this.showNotification('分析失败，请重试', 'error');
        } finally {
            this.hideLoading();
        }
    }

    // 显示相似度分析结果
    displaySimilarityResult(data) {
        const resultsContainer = document.getElementById('similarityResults');
        const percentage = (data.similarity * 100).toFixed(2);
        
        resultsContainer.innerHTML = `
            <div class="similarity-result-card">
                <div class="similarity-score">${percentage}%</div>
                <div class="similarity-percentage">相似度</div>
                <div class="file-names">
                    <div class="file-name">${data.file1}</div>
                    <div class="vs-indicator">VS</div>
                    <div class="file-name">${data.file2}</div>
                </div>
            </div>
        `;
    }

    // 加载历史记录
    async loadHistory() {
        const historyList = document.getElementById('historyList');
        
        // 显示加载状态
        historyList.innerHTML = `
            <div class="loading">
                <i class="fas fa-spinner fa-spin"></i>
                <span>加载中...</span>
            </div>
        `;

        try {
            const response = await fetch('/api/history');
            const data = await response.json();

            if (data.success) {
                if (data.history.length === 0) {
                    historyList.innerHTML = `
                        <div class="help-placeholder">
                            <i class="fas fa-history"></i>
                            <p>暂无历史记录</p>
                        </div>
                    `;
                } else {
                    historyList.innerHTML = data.history
                        .reverse()
                        .map(item => `<div class="history-item">${item}</div>`)
                        .join('');
                }
            } else {
                historyList.innerHTML = `
                    <div class="help-placeholder">
                        <i class="fas fa-exclamation-circle"></i>
                        <p>加载历史记录失败</p>
                    </div>
                `;
            }
        } catch (error) {
            console.error('加载历史记录时出错:', error);
            historyList.innerHTML = `
                <div class="help-placeholder">
                    <i class="fas fa-exclamation-circle"></i>
                    <p>加载失败，请重试</p>
                </div>
            `;
        }
    }

    // 切换语言
    async toggleLanguage() {
        const newLanguage = this.currentLanguage === 'zh-cn' ? 'en' : 'zh-cn';
        await this.changeLanguage(newLanguage);
    }

    // 更改语言
    async changeLanguage(language) {
        try {
            const response = await fetch('/api/language', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ language: language })
            });

            const data = await response.json();

            if (data.success) {
                this.currentLanguage = language;
                this.loadLanguage();
                this.showNotification('语言已切换', 'success');
            }
        } catch (error) {
            console.error('切换语言时出错:', error);
            this.showNotification('切换语言失败', 'error');
        }
    }

    // 更改主题
    changeTheme(theme) {
        if (theme === 'dark') {
            document.body.classList.add('dark-theme');
        } else {
            document.body.classList.remove('dark-theme');
        }
        
        // 保存主题设置到本地存储
        localStorage.setItem('theme', theme);
    }

    // 加载配置
    async loadConfig() {
        try {
            const response = await fetch('/api/config');
            const config = await response.json();
            
            this.currentLanguage = config.language || 'zh-cn';
            
            // 设置语言选择器的值
            document.getElementById('languageSelect').value = this.currentLanguage;
            
            // 加载保存的主题
            const savedTheme = localStorage.getItem('theme') || 'light';
            document.getElementById('themeSelect').value = savedTheme;
            this.changeTheme(savedTheme);
            
        } catch (error) {
            console.error('加载配置时出错:', error);
        }
    }

    // 加载语言
    loadLanguage() {
        const translations = {
            'zh-cn': {
                'nav-chat': '聊天',
                'nav-help': '帮助',
                'nav-similarity': '查重',
                'nav-history': '历史',
                'nav-settings': '设置',
                'chat-title': '与AI助手聊天',
                'chat-subtitle': 'Lynn是一个智能的程序编程助手，擅长解答各种编程问题',
                'welcome-message': '你好！我是Lynn，你的编程助手。有什么我可以帮助你的吗？',
                'help-title': 'C语言帮助',
                'help-subtitle': '查询C语言关键字、语法和头文件说明',
                'help-placeholder': '请输入要查询的内容',
                'similarity-title': '代码查重',
                'similarity-subtitle': '上传两个C语言文件，检测代码相似度',
                'upload-file1': '选择第一个文件',
                'upload-file2': '选择第二个文件',
                'analyze-btn': '分析相似度',
                'code-preview-title': '代码预览',
                'toggle-preview': '隐藏预览',
                'file1-preview': '文件1',
                'file2-preview': '文件2',
                'history-title': '操作历史',
                'refresh': '刷新',
                'loading': '加载中...',
                'settings-title': '设置',
                'language-setting': '界面语言',
                'theme-setting': '主题',
                'processing': '处理中...'
            },
            'en': {
                'nav-chat': 'Chat',
                'nav-help': 'Help',
                'nav-similarity': 'Similarity',
                'nav-history': 'History',
                'nav-settings': 'Settings',
                'chat-title': 'Chat with AI Assistant',
                'chat-subtitle': 'Lynn is an intelligent programming assistant, good at answering various programming questions',
                'welcome-message': 'Hello! I am Lynn, your programming assistant. How can I help you?',
                'help-title': 'C Language Help',
                'help-subtitle': 'Query C language keywords, syntax and header file descriptions',
                'help-placeholder': 'Please enter content to search',
                'similarity-title': 'Code Similarity Detection',
                'similarity-subtitle': 'Upload two C language files to detect code similarity',
                'upload-file1': 'Select First File',
                'upload-file2': 'Select Second File',
                'analyze-btn': 'Analyze Similarity',
                'code-preview-title': 'Code Preview',
                'toggle-preview': 'Hide Preview',
                'file1-preview': 'File 1',
                'file2-preview': 'File 2',
                'history-title': 'Operation History',
                'refresh': 'Refresh',
                'loading': 'Loading...',
                'settings-title': 'Settings',
                'language-setting': 'Interface Language',
                'theme-setting': 'Theme',
                'processing': 'Processing...'
            }
        };

        const currentTranslations = translations[this.currentLanguage];
        
        document.querySelectorAll('[data-lang-key]').forEach(element => {
            const key = element.getAttribute('data-lang-key');
            if (currentTranslations[key]) {
                element.textContent = currentTranslations[key];
            }
        });

        // 更新语言切换按钮
        document.getElementById('currentLang').textContent = 
            this.currentLanguage === 'zh-cn' ? '中文' : 'English';

        // 更新输入框占位符
        if (this.currentLanguage === 'zh-cn') {
            document.getElementById('chatInput').placeholder = '输入你的问题...';
            document.getElementById('helpInput').placeholder = '输入关键字、语句或头文件名...';
        } else {
            document.getElementById('chatInput').placeholder = 'Type your question...';
            document.getElementById('helpInput').placeholder = 'Enter keywords, statements or header file names...';
        }
    }

    // 初始化标签页
    initializeTabs() {
        // 默认显示聊天页面
        this.switchTab('chat');
    }

    // 显示加载状态
    showLoading() {
        this.isLoading = true;
        document.getElementById('loadingOverlay').classList.add('show');
    }

    // 隐藏加载状态
    hideLoading() {
        this.isLoading = false;
        document.getElementById('loadingOverlay').classList.remove('show');
    }

    // 显示通知
    showNotification(message, type = 'info') {
        const notification = document.getElementById('notification');
        const textElement = notification.querySelector('.notification-text');
        
        textElement.textContent = message;
        notification.className = `notification ${type} show`;

        // 自动隐藏通知
        setTimeout(() => {
            this.hideNotification();
        }, 5000);
    }

    // 隐藏通知
    hideNotification() {
        document.getElementById('notification').classList.remove('show');
    }
}

// 应用程序启动
document.addEventListener('DOMContentLoaded', () => {
    window.app = new CAgentApp();
});

// 全局错误处理
window.addEventListener('error', (e) => {
    console.error('全局错误:', e.error);
    if (window.app) {
        window.app.showNotification('出现了一个错误，请刷新页面重试', 'error');
    }
});

// 全局未处理的Promise拒绝
window.addEventListener('unhandledrejection', (e) => {
    console.error('未处理的Promise拒绝:', e.reason);
    if (window.app) {
        window.app.showNotification('出现了一个错误，请重试', 'error');
    }
});