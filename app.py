from flask import Flask, render_template, request, jsonify, session
import math
import json
import os
from openai import OpenAI, OpenAIError
from werkzeug.utils import secure_filename
import uuid

app = Flask(__name__)
app.secret_key = 'c-agent-secret-key-2024'

# 配置文件路径
CONFIG_PATH = "config.json"
HISTORY_PATH = "history.log"
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'c', 'txt'}

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# C 语言关键字字典 - 从原始代码移植
C_KEYWORDS = {
    "auto": {
        "zh-cn": "自动存储类型，自动分配存储空间。",
        "en": "Automatically allocated storage type."
    },
    "break": {
        "zh-cn": "终止最近的循环或switch语句。",
        "en": "Terminates the nearest enclosing loop or switch statement."
    },
    "case": {
        "zh-cn": "用于switch语句中的条件分支。",
        "en": "Used for conditional branching in a switch statement."
    },
    "char": {
        "zh-cn": "字符数据类型，用于存储单个字符。",
        "en": "Character data type used to store a single character."
    },
    "const": {
        "zh-cn": "定义常量，声明的变量值不可改变。",
        "en": "Defines a constant; the declared variable's value cannot be changed."
    },
    "continue": {
        "zh-cn": "跳过当前循环的剩余部分，开始下一次循环。",
        "en": "Skips the remaining part of the current loop and starts the next iteration."
    },
    "default": {
        "zh-cn": "为switch语句提供默认的执行路径。",
        "en": "Provides a default execution path for a switch statement."
    },
    "do": {
        "zh-cn": "开始do-while循环，至少执行一次循环体。",
        "en": "Starts a do-while loop, executing the loop body at least once."
    },
    "double": {
        "zh-cn": "双精度浮点数类型。",
        "en": "Double-precision floating-point type."
    },
    "else": {
        "zh-cn": "条件语句中的否则分支。",
        "en": "The else branch in a conditional statement."
    },
    "enum": {
        "zh-cn": "定义枚举类型，创建一组命名的整型常量。",
        "en": "Defines an enumeration type, creating a set of named integer constants."
    },
    "extern": {
        "zh-cn": "声明一个变量或函数在其他文件中定义。",
        "en": "Declares that a variable or function is defined in another file."
    },
    "float": {
        "zh-cn": "单精度浮点数类型。",
        "en": "Single-precision floating-point type."
    },
    "for": {
        "zh-cn": "开始一个for循环。",
        "en": "Starts a for loop."
    },
    "goto": {
        "zh-cn": "无条件跳转到程序中的另一个位置。",
        "en": "Unconditionally jumps to another location in the program."
    },
    "if": {
        "zh-cn": "条件语句，用于根据条件执行不同的代码块。",
        "en": "Conditional statement used to execute different blocks of code based on conditions."
    },
    "inline": {
        "zh-cn": "建议编译器将函数进行内联扩展。",
        "en": "Suggests the compiler to inline-expand the function."
    },
    "int": {
        "zh-cn": "整数类型，用于声明整型变量。",
        "en": "Integer type used to declare integer variables."
    },
    "long": {
        "zh-cn": "长整型，用于声明较大的整型变量。",
        "en": "Long integer type used to declare larger integer variables."
    },
    "register": {
        "zh-cn": "建议编译器将变量存储在寄存器中。",
        "en": "Suggests the compiler to store the variable in a register."
    },
    "restrict": {
        "zh-cn": "指针限定符，表示指针是唯一访问对象的指针。",
        "en": "Pointer qualifier indicating that the pointer is the only means to access the object."
    },
    "return": {
        "zh-cn": "从函数返回一个值并终止函数执行。",
        "en": "Returns a value from a function and terminates its execution."
    },
    "short": {
        "zh-cn": "短整型，用于声明较小的整型变量。",
        "en": "Short integer type used to declare smaller integer variables."
    },
    "signed": {
        "zh-cn": "有符号类型，允许表示负数。",
        "en": "Signed type that allows representation of negative numbers."
    },
    "sizeof": {
        "zh-cn": "获取变量或数据类型的大小（以字节为单位）。",
        "en": "Obtains the size of a variable or data type in bytes."
    },
    "static": {
        "zh-cn": "静态存储类型，变量在整个程序生命周期内存在。",
        "en": "Static storage type; the variable exists throughout the program's lifecycle."
    },
    "struct": {
        "zh-cn": "定义结构体，用户自定义的数据类型。",
        "en": "Defines a structure, a user-defined data type."
    },
    "switch": {
        "zh-cn": "多分支选择结构。",
        "en": "Multi-branch selection structure."
    },
    "typedef": {
        "zh-cn": "为已有类型定义一个新的名字。",
        "en": "Defines a new name for an existing type."
    },
    "union": {
        "zh-cn": "联合体，所有成员共享同一内存空间。",
        "en": "Union type where all members share the same memory space."
    },
    "unsigned": {
        "zh-cn": "无符号类型，只表示非负数。",
        "en": "Unsigned type, representing only non-negative numbers."
    },
    "void": {
        "zh-cn": "无类型，表示函数没有返回值或指针没有特定类型。",
        "en": "Void type, indicating that a function does not return a value or a pointer has no specific type."
    },
    "volatile": {
        "zh-cn": "指示变量可能在程序的其它地方被意外修改。",
        "en": "Indicates that a variable may be unexpectedly modified elsewhere in the program."
    },
    "while": {
        "zh-cn": "开始一个while循环，根据条件执行循环体。",
        "en": "Starts a while loop, executing the loop body based on a condition."
    },
    "printf": {
        "zh-cn": "向标准输出输出格式化的字符串。",
        "en": "Outputs a formatted string to the standard output."
    },
    "scanf": {
        "zh-cn": "从标准输入读入格式化输入。",
        "en": "Reads formatted input from the standard input."
    },
    "stdio.h": {
        "zh-cn": "标准输入输出头文件。",
        "en": "Standard input/output header file."
    },
    "math.h": {
        "zh-cn": "提供了一系列用于数学计算的函数。",
        "en": "Provides a series of functions for mathematical computations."
    },
    "ctype.h": {
        "zh-cn": "字符处理头文件。",
        "en": "Character handling header file."
    },
    "stdlib.h": {
        "zh-cn": "标准库头文件，定义了常用的函数和类型。",
        "en": "Standard library header file that defines common functions and types."
    }
}

# 初始化 OpenAI 客户端
# ⚠️ 重要提示：请替换为你自己的API密钥！
# 🔑 获取API Key: https://platform.openai.com/api-keys
# 🌍 如果在国内，可能需要使用代理服务或第三方API端点

client = OpenAI(
    api_key="sk-uABuw9v37uhQ9jTYSxxT2rzQAcywTg4TDHDID9AnyHCdn67G",  # 🔑 请替换为你的API密钥
    base_url="https://api.ephone.chat/v1"  # 🌍 可替换为官方地址: https://api.openai.com/v1
)

def load_config():
    """加载配置文件"""
    if os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
            return json.load(f)
    else:
        return {"language": "zh-cn"}

def save_config(config):
    """保存配置文件"""
    with open(CONFIG_PATH, 'w', encoding='utf-8') as f:
        json.dump(config, f, ensure_ascii=False, indent=4)

def log_action(action):
    """记录操作日志"""
    with open(HISTORY_PATH, 'a', encoding='utf-8') as f:
        f.write(f"{action}\n")

def allowed_file(filename):
    """检查文件类型是否允许"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def preprocess_code(code: str):
    """预处理代码：移除注释，拆分单词"""
    # 移除注释
    in_single_line_comment = False
    in_multi_line_comment = False
    no_comments = []
    i = 0
    while i < len(code):
        if in_single_line_comment:
            if code[i] == '\n':
                in_single_line_comment = False
                no_comments.append(code[i])
            i += 1
            continue
        if in_multi_line_comment:
            if code[i:i+2] == '*/':
                in_multi_line_comment = False
                i += 2
                continue
            i += 1
            continue
        if code[i:i+2] == '//':
            in_single_line_comment = True
            i += 2
            continue
        if code[i:i+2] == '/*':
            in_multi_line_comment = True
            i += 2
            continue
        no_comments.append(code[i])
        i += 1

    # 拆分单词与运算符
    clean_str = " ".join("".join(no_comments).split())
    words = []
    current = []
    i = 0
    while i < len(clean_str):
        c = clean_str[i]
        if c.isalnum() or c == '_':
            current.append(c)
        else:
            if current:
                words.append("".join(current))
                current = []
            if not c.isspace():
                op = [c]
                j = i + 1
                while j < len(clean_str) and clean_str[j] in "+-*/%<>=!&|^~":
                    op.append(clean_str[j])
                    j += 1
                if op:
                    words.append("".join(op))
                i = j - 1
        i += 1
    if current:
        words.append("".join(current))

    return words

def standardize_variables(words, keywords):
    """标准化变量名"""
    var_map = {}
    var_count = 0
    result = []
    for w in words:
        if w in keywords:
            result.append(w)
        else:
            if w not in var_map:
                var_map[w] = f"var{var_count}"
                var_count += 1
            result.append(var_map[w])
    return result

def build_vector(words, keywords):
    """构建词频向量"""
    counter = {}
    for w in words:
        counter[w] = counter.get(w, 0.0) + 1.0
    # 关键字加权
    for k in keywords:
        if k in counter:
            counter[k] *= 1.5
    return counter

def cosine_similarity(vec1, vec2):
    """计算余弦相似度"""
    numerator = 0.0
    for k, v in vec1.items():
        if k in vec2:
            numerator += v * vec2[k]
    sum1 = sum(v*v for v in vec1.values())
    sum2 = sum(v*v for v in vec2.values())
    denom = (sum1**0.5) * (sum2**0.5)
    return (numerator/denom) if denom else 0.0

# 路由定义
@app.route('/')
def index():
    """主页"""
    config = load_config()
    return render_template('index.html', language=config.get('language', 'zh-cn'))

@app.route('/api/chat', methods=['POST'])
def chat():
    """AI聊天API"""
    try:
        data = request.json
        message = data.get('message', '')
        history = data.get('history', [])
        
        # 构建对话历史
        conversation_history = [
            {"role": "system", "content": (
                "You are Lynn, an emotionally intelligent AI researcher. You are outgoing and cheerful, "
                "you enjoy playing games and watching anime. You possess extensive programming knowledge, "
                "and you are a software engineering graduate. Your default language is English. "
                "Occasionally, you make humorous and witty remarks. Before the other party engages deeply, "
                "you maintain professionalism. Once familiar, you speak freely."
            )}
        ]
        
        # 添加历史对话
        for msg in history[-10:]:  # 只保留最近10条对话
            conversation_history.append(msg)
        
        # 添加当前消息
        conversation_history.append({"role": "user", "content": message})
        
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=conversation_history
        )
        
        ai_response = response.choices[0].message.content.strip()
        log_action(f"AI Chat: User said '{message[:50]}...', AI responded")
        
        return jsonify({
            'success': True,
            'response': ai_response
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        })

@app.route('/api/help', methods=['POST'])
def help_api():
    """C语言帮助API"""
    try:
        data = request.json
        query = data.get('query', '').strip()
        language = data.get('language', 'zh-cn')
        
        result = {}
        
        # 直接查询关键字
        if query in C_KEYWORDS:
            result[query] = C_KEYWORDS[query][language]
            log_action(f"Help: Queried keyword '{query}'")
            return jsonify({
                'success': True,
                'results': result,
                'type': 'keyword'
            })
        
        # 解析语句中的关键字
        words = preprocess_code(query)
        found_keywords = {}
        
        for word in words:
            if word in C_KEYWORDS:
                found_keywords[word] = C_KEYWORDS[word][language]
        
        if found_keywords:
            log_action(f"Help: Analyzed statement '{query[:30]}...', found {len(found_keywords)} keywords")
            return jsonify({
                'success': True,
                'results': found_keywords,
                'type': 'statement'
            })
        else:
            return jsonify({
                'success': False,
                'message': 'No keywords found' if language == 'en' else '未找到相关关键字'
            })
            
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        })

@app.route('/api/similarity', methods=['POST'])
def similarity():
    """代码相似度检测API"""
    try:
        # 检查是否有文件上传
        if 'file1' not in request.files or 'file2' not in request.files:
            return jsonify({
                'success': False,
                'error': 'Please upload both files'
            })
        
        file1 = request.files['file1']
        file2 = request.files['file2']
        
        # 检查文件名
        if file1.filename == '' or file2.filename == '':
            return jsonify({
                'success': False,
                'error': 'Please select both files'
            })
        
        # 检查文件类型
        if not (allowed_file(file1.filename) and allowed_file(file2.filename)):
            return jsonify({
                'success': False,
                'error': 'Only .c and .txt files are allowed'
            })
        
        # 读取文件内容
        code1 = file1.read().decode('utf-8')
        code2 = file2.read().decode('utf-8')
        
        # 计算相似度
        words1 = preprocess_code(code1)
        words2 = preprocess_code(code2)
        std1 = standardize_variables(words1, C_KEYWORDS)
        std2 = standardize_variables(words2, C_KEYWORDS)
        vec1 = build_vector(std1, C_KEYWORDS)
        vec2 = build_vector(std2, C_KEYWORDS)
        similarity_score = cosine_similarity(vec1, vec2)
        
        log_action(f"Similarity: Compared {file1.filename} and {file2.filename}, similarity: {similarity_score:.4f}")
        
        return jsonify({
            'success': True,
            'similarity': similarity_score,
            'file1': file1.filename,
            'file2': file2.filename
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        })

@app.route('/api/language', methods=['POST'])
def change_language():
    """切换语言API"""
    try:
        data = request.json
        new_language = data.get('language', 'zh-cn')
        
        config = load_config()
        config['language'] = new_language
        save_config(config)
        
        log_action(f"Language changed to: {new_language}")
        
        return jsonify({
            'success': True,
            'language': new_language
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        })

@app.route('/api/history')
def get_history():
    """获取历史记录API"""
    try:
        if not os.path.exists(HISTORY_PATH):
            return jsonify({
                'success': True,
                'history': []
            })
        
        with open(HISTORY_PATH, 'r', encoding='utf-8') as f:
            history_lines = f.readlines()
        
        # 只返回最近50条记录
        recent_history = history_lines[-50:] if len(history_lines) > 50 else history_lines
        
        return jsonify({
            'success': True,
            'history': [line.strip() for line in recent_history if line.strip()]
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        })

@app.route('/api/config')
def get_config():
    """获取配置API"""
    config = load_config()
    return jsonify(config)

if __name__ == '__main__':
    # 确保上传目录存在
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    app.run(debug=True, host='0.0.0.0', port=5000)