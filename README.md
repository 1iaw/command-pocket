# 命令口袋 Command Pocket

一个使用 Tauri 2 开发的轻量桌面悬浮命令工具。点击悬浮方块展开常用命令，点击命令即可复制；复制新命令后，可以通过快捷键快速添加并自动命名。

## MVP 功能

- 48 × 48 悬浮方块，始终置顶
- 点击展开/收起命令列表
- 点击整行复制命令，并显示复制成功反馈
- 从剪贴板快速添加命令
- 根据 Git、Go、SSH、curl、npm、kinit 等命令自动命名和分组
- 命令置顶、删除
- 浏览器本地存储持久化，不依赖账号和网络
- JWT、Cookie、私钥和密码参数检测
- 全局快捷键：
  - `⌥ Space`：展开/收起
  - `⌥ ⇧ Space`：快速添加剪贴板命令

## 技术栈

- Tauri 2
- TypeScript
- Vite
- Rust
- 官方 Clipboard Manager 与 Global Shortcut 插件

## Mac 环境准备

不需要下载完整 Xcode。只开发 macOS 桌面应用时，安装 Apple Command Line Tools 即可：

```bash
xcode-select --install
```

安装 Rust：

```bash
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
source "$HOME/.cargo/env"
```

确认 Node.js 已安装：

```bash
node -v
npm -v
```

## 运行

```bash
git pull
npm install
npm run tauri dev
```

日常可以直接使用 VS Code、Cursor、WebStorm 等 IDE 打开仓库。

## 构建 `.app`

```bash
npm run tauri build
```

生成结果位于：

```text
src-tauri/target/release/bundle/macos/
```

## 仅预览界面

不启动 Rust 壳时，可以只运行前端：

```bash
npm run dev
```

浏览器预览会自动使用降级模式：剪贴板使用浏览器 API，全局快捷键不可用。

## 前端测试

```bash
npm test
```

## 项目结构

```text
src/
├── main.ts
├── style.css
├── command-store.ts
├── naming-service.ts
└── types.ts

src-tauri/
├── capabilities/default.json
├── src/lib.rs
├── Cargo.toml
└── tauri.conf.json
```

## 安全说明

工具只保存和复制命令，不会直接执行命令。检测到明显的 Token、Cookie、私钥或密码参数时会阻止保存。

