#!/bin/bash

# 导入通用函数
source "$(dirname "$0")/common.sh"

# Tauri Node.js 版本
TAURI_NODE_VERSION="20.10.0"

start_desktop() {
    # 启用 Rust 编译缓存
    if command -v sccache &> /dev/null; then
        export RUSTC_WRAPPER=sccache
        export SCCACHE_DIR=$HOME/.cache/sccache
        export SCCACHE_CACHE_SIZE="10G"
        mkdir -p $SCCACHE_DIR
        echo -e "${GREEN}⚡ Rust 编译缓存已启用 (sccache)${NC}"
    fi

    # 检查根目录依赖
    echo -e "${BLUE}🔍 检查根目录依赖...${NC}"
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}⚠️ 根目录依赖未安装，正在安装...${NC}"
        yarn install
    else
        echo -e "${GREEN}✅ 根目录依赖已安装${NC}"
    fi

    # 检查 Tauri CLI
    echo -e "${BLUE}🔍 检查 Tauri 依赖...${NC}"
    if ! command -v cargo-tauri &> /dev/null; then
        echo -e "${YELLOW}⚠️ 安装 Tauri CLI...${NC}"
        cargo install tauri-cli
    fi

    # 设置正确的 Node.js 版本
    setup_nvm
    use_node_version $TAURI_NODE_VERSION

    # 启动 Tauri
    echo -e "${BLUE}🚀 启动桌面应用...${NC}"
    echo -e "${YELLOW}执行命令: ${NC}yarn tauri dev"
    # 创建日志目录
    mkdir -p logs
    # 生成日志文件名
    LOG_FILE="logs/desktop_$(date +%Y%m%d_%H%M%S).log"
    echo -e "${GREEN}桌面应用日志输出到: ${LOG_FILE}${NC}"
    # 使用 tee 命令同时输出到文件和控制台，并在后台启动 tail 来监控错误
    yarn tauri dev 2>&1 | tee "${LOG_FILE}" | grep --line-buffered -i "error\|exception\|fail\|warn\|ERR_\|panic\|RUST_BACKTRACE\|thread.*panicked" &
    # 保存后台进程的 PID
    DESKTOP_PID=$!
    # 设置清理函数
    cleanup() {
        echo -e "\n${BLUE}🛑 停止桌面应用...${NC}"
        kill $DESKTOP_PID 2>/dev/null
        exit 0
    }
    # 设置清理钩子
    trap cleanup SIGINT SIGTERM
    # 等待桌面应用进程结束
    wait $DESKTOP_PID
}

# 如果直接运行此脚本，则启动桌面应用
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    start_desktop
fi
