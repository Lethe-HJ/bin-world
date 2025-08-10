#!/bin/bash

# 导入通用函数
source "$(dirname "$0")/common.sh"

# 清理函数
cleanup() {
    echo -e "\n${BLUE}🛑 停止所有开发服务...${NC}"
    echo -e "${YELLOW}执行命令: ${NC}kill \$(jobs -p)"
    kill $(jobs -p) 2>/dev/null
    exit 0
}

# 设置清理钩子
trap cleanup SIGINT SIGTERM

echo -e "${BLUE}🚀 启动 Bin World 开发环境...${NC}"

# 清理所有已知端口
echo -e "${BLUE}清理端口...${NC}"
cleanup_ports

# 启动前端
echo -e "${BLUE}启动前端服务...${NC}"
echo -e "${YELLOW}执行命令: ${NC}frontend/scripts/dev.sh"
frontend/scripts/dev.sh &
FRONTEND_PID=$!
echo -e "${GREEN}前端服务进程 ID: ${FRONTEND_PID}${NC}"

# 启动后端
echo -e "${BLUE}启动后端服务...${NC}"
echo -e "${YELLOW}执行命令: ${NC}backend/dev.sh"
backend/dev.sh &
BACKEND_PID=$!
echo -e "${GREEN}后端服务进程 ID: ${BACKEND_PID}${NC}"

# 等待前端就绪
echo -e "${BLUE}等待前端服务就绪...${NC}"
echo -e "${YELLOW}执行命令: ${NC}curl -s http://localhost:5173"
while ! curl -s http://localhost:5173 > /dev/null; do
    sleep 1
done
echo -e "${GREEN}前端服务已就绪${NC}"

# 启动桌面应用
echo -e "${BLUE}启动桌面应用...${NC}"
echo -e "${YELLOW}执行命令: ${NC}$(dirname "$0")/desktop.sh"
"$(dirname "$0")/desktop.sh"

# 等待所有后台进程完成
echo -e "${BLUE}等待所有服务完成...${NC}"
echo -e "${YELLOW}执行命令: ${NC}wait"
wait

