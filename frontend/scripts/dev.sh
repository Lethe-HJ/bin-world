#!/bin/bash

# 导入通用函数
source "$(dirname "$0")/common.sh"

# 前端 Node.js 版本
FRONTEND_NODE_VERSION="22.14.0"

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 获取前端项目根目录
FRONTEND_ROOT="$(dirname "$SCRIPT_DIR")"
# 获取主项目根目录
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

start_frontend() {
    # 记录原始工作目录
    ORIGINAL_PWD="$PWD"
    # 切换到前端项目根目录
    cd "$FRONTEND_ROOT"
    # 设置日志目录和文件名
    if [[ "$ORIGINAL_PWD" == "$PROJECT_ROOT" ]]; then
        LOG_DIR="frontend/logs"
        mkdir -p "$PROJECT_ROOT/$LOG_DIR"
        LOG_FILE="$PROJECT_ROOT/$LOG_DIR/frontend_$(date +%Y%m%d_%H%M%S).log"
    else
        LOG_DIR="logs"
        mkdir -p "$LOG_DIR"
        LOG_FILE="$LOG_DIR/frontend_$(date +%Y%m%d_%H%M%S).log"
    fi
    # 设置正确的 Node.js 版本
    echo -e "${BLUE}设置 Node.js 环境...${NC}"
    echo -e "${YELLOW}执行命令: ${NC}nvm use $FRONTEND_NODE_VERSION"
    setup_nvm
    use_node_version $FRONTEND_NODE_VERSION

    # 检查前端依赖
    echo -e "${BLUE}🔍 检查前端依赖...${NC}"

    # 检查是否需要重新安装依赖
    local need_install=false
    if [ ! -d "node_modules" ]; then
        need_install=true
    fi

    if [ "$need_install" = true ]; then
        echo -e "${YELLOW}⚠️ 前端依赖未安装，正在安装...${NC}"
        echo -e "${YELLOW}执行命令: ${NC}yarn install"
        yarn install
    else
        echo -e "${GREEN}✅ 前端依赖已安装${NC}"
    fi
    
    # 启动前端
    echo -e "${BLUE}📱 启动前端 (Vue.js)...${NC}"
    echo -e "${YELLOW}执行命令: ${NC}npx vite"
    # 显示日志路径
    if [[ "$ORIGINAL_PWD" == "$PROJECT_ROOT" ]]; then
        echo -e "${GREEN}前端服务日志输出到: frontend/logs/frontend_$(date +%Y%m%d_%H%M%S).log${NC}"
    else
        echo -e "${GREEN}前端服务日志输出到: logs/frontend_$(date +%Y%m%d_%H%M%S).log${NC}"
    fi
    # 使用 tee 命令同时输出到文件和控制台，并在后台启动 tail 来监控错误
    npx vite 2>&1 | tee "${LOG_FILE}" | grep --line-buffered -i "error\|exception\|fail\|warn\|ERR_\|ELIFECYCLE" &
    # 保存后台进程的 PID
    FRONTEND_PID=$!
    # 设置清理函数
    cleanup() {
        echo -e "\n${BLUE}🛑 停止前端服务...${NC}"
        kill $FRONTEND_PID 2>/dev/null
        exit 0
    }
    # 设置清理钩子
    trap cleanup SIGINT SIGTERM
    # 等待前端进程结束
    wait $FRONTEND_PID
}

# 如果直接运行此脚本，则启动前端
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    start_frontend
fi