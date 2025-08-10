#!/bin/bash

# 颜色定义
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m'

# 检查端口占用并清理进程
check_and_clean_port() {
    local port=$1
    local process_name=$2
    
    # 获取占用端口的进程信息
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        pids=$(lsof -i :${port} -t)
        if [ ! -z "$pids" ]; then
            echo -e "${YELLOW}⚠️ 端口 ${port} 被占用${NC}"
            
            # 对每个 pid 进行检查
            for pid in $pids; do
                # 在 macOS 上使用 ps 命令
                process_info=$(ps -p $pid -c -o comm=)
                
                # 检查是否是我们的进程
                if [[ $process_info == *"python"* ]] || [[ $process_info == *"robyn"* ]]; then
                    echo -e "${BLUE}🔍 确认是 web 后端进程 (PID: ${pid})，准备清理...${NC}"
                    kill -9 $pid
                    echo -e "${GREEN}✅ 已终止进程${NC}"
                else
                    echo -e "${RED}❌ 端口被其他程序占用：${process_info} (PID: ${pid})${NC}"
                    echo -e "${RED}请手动处理端口占用问题${NC}"
                    exit 1
                fi
            done
        else
            echo -e "${GREEN}✅ 端口 ${port} 可用${NC}"
        fi
    else
        # Linux
        pid=$(netstat -tulpn 2>/dev/null | grep ":${port}" | awk '{print $7}' | cut -d'/' -f1)
        if [ ! -z "$pid" ]; then
            echo -e "${YELLOW}⚠️ 端口 ${port} 被进程 ${pid} 占用${NC}"
            process_info=$(ps -p $pid -o comm=)
            
            if [[ $process_info == *"python"* ]] || [[ $process_info == *"robyn"* ]]; then
                echo -e "${BLUE}🔍 确认是 web 后端进程，准备清理...${NC}"
                kill -9 $pid
                echo -e "${GREEN}✅ 已终止旧进程${NC}"
            else
                echo -e "${RED}❌ 端口被其他程序占用：${process_info}${NC}"
                echo -e "${RED}请手动处理端口占用问题${NC}"
                exit 1
            fi
        else
            echo -e "${GREEN}✅ 端口 ${port} 可用${NC}"
        fi
    fi
}

# 检查并设置 nvm
setup_nvm() {
    echo -e "${BLUE}🔍 检查 nvm 安装...${NC}"
    if [ -z "$NVM_DIR" ]; then
        if [ -f "$HOME/.bash_profile" ]; then
            source "$HOME/.bash_profile"
        fi
        if [ -f "$HOME/.zshrc" ]; then
            source "$HOME/.zshrc"
        fi
    fi

    if [ -z "$NVM_DIR" ]; then
        echo -e "${RED}❌ nvm 未安装${NC}"
        exit 1
    fi

    # 加载 nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
}

# 设置 Node.js 版本
use_node_version() {
    local version=$1
    echo -e "${BLUE}🔄 切换到 Node.js ${version}...${NC}"
    nvm use $version || nvm install $version
    echo -e "${GREEN}✅ Node.js 版本 v${version} 已设置${NC}"
}

# 等待服务就绪
wait_for_service() {
    local url=$1
    local service_name=$2
    echo -e "${BLUE}⏳ 等待${service_name}就绪...${NC}"
    while ! curl -s $url > /dev/null; do
        sleep 1
    done
}

# 清理所有已知端口
cleanup_ports() {
    check_and_clean_port 8080 "python"  # 后端端口
    check_and_clean_port 5173 "node"    # 前端端口
}