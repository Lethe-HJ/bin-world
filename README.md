# Bin World - Tauri Desktop Application

This is a Tauri-based desktop application that provides a desktop shell for web applications.

## Project Architecture

This project follows a modular architecture with the following components:

- **Desktop Application**: Tauri-based desktop shell (this directory)
- **Frontend**: Vue.js web application (in `frontend/` directory)
- **Backend**: Python web backend using Robyn (in `backend/` directory)

## Development Setup

### Prerequisites

- [Node.js](https://nodejs.org/)
- [Rust](https://rustup.rs/)
- [Tauri CLI](https://tauri.app/v1/guides/getting-started/setup/)
- [Python 3.13+](https://www.python.org/)
- [Robyn](https://robyn.tech/) (for backend development)

### Recommended IDE Setup

- [VS Code](https://code.visualstudio.com/) + [Tauri](https://marketplace.visualstudio.com/items?itemName=tauri-apps.tauri-vscode) + [rust-analyzer](https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer)

### Development Workflow

The desktop application loads the frontend from a web URL. You can start all services with a single command:

```bash
# Start all development services
yarn dev
# or
./scripts/dev.sh
```

This command will:
1. Start the frontend development server on http://localhost:5173
2. Start the backend Robyn server on http://localhost:8080
3. Wait for the frontend to be ready
4. Launch the Tauri desktop application

### Alternative Commands

```bash
# Start only the Tauri desktop application (requires frontend to be running)
yarn tauri:dev

# Start only the backend Robyn server
cd backend && python app.py

# Build frontend (optional, for production deployment)
cd frontend
yarn build

# Build Tauri application
yarn tauri:build
```

## Project Structure

- `src-tauri/`: Tauri backend (Rust)
- `frontend/`: Vue.js frontend application (runs on http://localhost:5173)
- `backend/`: Python web backend using Robyn (runs on http://localhost:8080)
- `docs/`: Project documentation
- `scripts/`: Development and utility scripts
  - `dev.sh`: Development startup script

## Configuration

The Tauri application is configured to load the frontend from `http://localhost:5173` by default. You can modify this URL in `src-tauri/tauri.conf.json` if needed.

## 子项目代码管理

本项目使用 git subtree 管理子项目代码。Frontend 和 Backend 分别维护在独立的仓库中：

- Frontend: `git@github.com:Lethe-HJ/bin-world-frontend.git`
- Backend: `git@github.com:Lethe-HJ/bin-world-backend.git`

### 提交子项目代码

当你修改了子项目的代码后，需要使用以下命令提交到对应的仓库：

```bash
# 提交 Frontend 的修改
git add frontend/
git commit -m "your commit message"
git subtree push --prefix frontend frontend master

# 提交 Backend 的修改
git add backend/
git commit -m "your commit message"
git subtree push --prefix backend backend main
```

### 拉取子项目更新

如果需要从远程仓库拉取子项目的更新：

```bash
# 拉取 Frontend 的更新
git subtree pull --prefix frontend frontend master --squash

# 拉取 Backend 的更新
git subtree pull --prefix backend backend main --squash
```

### 注意事项

1. Frontend 的 `resource` 目录管理：
   - 只有 `resource/readme.md` 会被 git 追踪
   - 其他资源文件不会被提交到仓库
   - 需要通过其他方式（如网盘）共享大文件资源

2. 分支管理：
   - Frontend 使用 `master` 分支
   - Backend 使用 `main` 分支
   - 主项目使用 `main` 分支
