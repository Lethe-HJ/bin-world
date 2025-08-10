#!/bin/bash

# 导入通用函数
source "$(dirname "$0")/common.sh"

# Python 版本
PYTHON_VERSION="3.13.5"

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 获取后端项目根目录
BACKEND_ROOT="$SCRIPT_DIR"
# 获取主项目根目录
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

start_backend() {
    # 记录原始工作目录
    ORIGINAL_PWD="$PWD"
    # 切换到后端项目根目录
    cd "$BACKEND_ROOT"
    # 设置日志目录和文件名
    if [[ "$ORIGINAL_PWD" == "$PROJECT_ROOT" ]]; then
        LOG_DIR="backend/logs"
        mkdir -p "$PROJECT_ROOT/$LOG_DIR"
        LOG_FILE="$PROJECT_ROOT/$LOG_DIR/backend_$(date +%Y%m%d_%H%M%S).log"
    else
        LOG_DIR="logs"
        mkdir -p "$LOG_DIR"
        LOG_FILE="$LOG_DIR/backend_$(date +%Y%m%d_%H%M%S).log"
    fi
    # 检查 conda 安装
    echo -e "${BLUE}🔍 检查 conda 安装...${NC}"
    if ! command -v conda &> /dev/null; then
        echo -e "${RED}❌ conda 未安装${NC}"
        exit 1
    fi

    # 检查 Python 版本
    echo -e "${BLUE}🔍 检查 Python 版本...${NC}"
    echo -e "${YELLOW}执行命令: ${NC}conda info --base"
    PYTHON_PATH=$(conda info --base)/bin/python
    echo -e "${GREEN}Python 路径: ${PYTHON_PATH}${NC}"

    if [ ! -f "$PYTHON_PATH" ] || [[ "$($PYTHON_PATH --version)" != *"$PYTHON_VERSION"* ]]; then
        echo -e "${YELLOW}⚠️ Python ${PYTHON_VERSION} 未安装，正在安装...${NC}"
        echo -e "${YELLOW}执行命令: ${NC}conda install -y python=$PYTHON_VERSION"
        conda install -y python=$PYTHON_VERSION
    fi
    echo -e "${GREEN}✅ Python 版本 Python ${PYTHON_VERSION} 已设置${NC}"

    # 检查 Python 虚拟环境
    echo -e "${BLUE}🔍 检查 Python 虚拟环境...${NC}"
    if [ ! -d "venv" ]; then
        echo -e "${YELLOW}⚠️ 创建 Python 虚拟环境...${NC}"
        echo -e "${YELLOW}执行命令: ${NC}$PYTHON_PATH -m venv venv"
        $PYTHON_PATH -m venv venv
    fi

    # 激活虚拟环境
    echo -e "${YELLOW}执行命令: ${NC}source venv/bin/activate"
    source venv/bin/activate

    # 检查 Python 依赖
    echo -e "${BLUE}🔍 检查 Python 依赖...${NC}"
    if [ ! -f "requirements.txt" ] || [ ! -d "venv/lib/python3.13/site-packages" ]; then
        echo -e "${YELLOW}⚠️ 安装 Python 依赖...${NC}"
        echo -e "${YELLOW}执行命令: ${NC}pip install -r requirements.txt"
        pip install -r requirements.txt
    else
        echo -e "${GREEN}✅ Python 依赖已安装${NC}"
    fi

    # 检查后端端口
    echo -e "${BLUE}🔍 检查后端端口...${NC}"
    check_and_clean_port 8080 "python"

    # 启动后端
    echo -e "${BLUE}🐍 启动后端 (Robyn)...${NC}"
    echo -e "${YELLOW}执行命令: ${NC}python app.py"
    # 显示日志路径
    if [[ "$ORIGINAL_PWD" == "$PROJECT_ROOT" ]]; then
        echo -e "${GREEN}后端服务日志输出到: backend/logs/backend_$(date +%Y%m%d_%H%M%S).log${NC}"
    else
        echo -e "${GREEN}后端服务日志输出到: logs/backend_$(date +%Y%m%d_%H%M%S).log${NC}"
    fi
    # 使用 tee 命令同时输出到文件和控制台，并在后台启动 tail 来监控错误
    python app.py 2>&1 | tee "${LOG_FILE}" | grep --line-buffered -i "error\|exception\|fail\|traceback" &
    # 保存后台进程的 PID
    BACKEND_PID=$!
    # 设置清理函数
    cleanup() {
        echo -e "\n${BLUE}🛑 停止后端服务...${NC}"
        kill $BACKEND_PID 2>/dev/null
        exit 0
    }
    # 设置清理钩子
    trap cleanup SIGINT SIGTERM
    # 等待后端进程结束
    wait $BACKEND_PID
}

# 如果直接运行此脚本，则启动后端
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    start_backend
fi