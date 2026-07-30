# 命令口袋 Command Pocket

一个轻量的 macOS 悬浮命令工具：常驻桌面边缘，展开后点击命令即可复制；复制新命令后，通过快捷键快速保存并自动命名。

## MVP 功能

- 桌面右侧悬浮方块，可拖动并记忆位置
- 点击方块展开/收起常用命令
- 点击整行复制命令，并显示复制成功反馈
- 从剪贴板快速添加命令
- 根据 Git、Go、SSH、curl、npm、kinit 等命令自动生成名称
- 命令分组、置顶和删除
- 本地 JSON 持久化，不依赖账号或网络
- 全局快捷键：
  - `⌥ Space`：展开/收起
  - `⌥ ⇧ Space`：快速添加剪贴板命令

## 在 Mac 上运行

### 推荐：XcodeGen

1. 安装 Xcode 和 XcodeGen：

   ```bash
   brew install xcodegen
   ```

2. 生成工程并打开：

   ```bash
   xcodegen generate
   open CommandPocket.xcodeproj
   ```

3. 在 Xcode 中选择 `CommandPocket` Scheme，点击 Run。

### Swift Package

也可以直接用 Xcode 打开 `Package.swift`，或者执行：

```bash
swift run CommandPocket
```

Swift Package 适合快速运行和测试；需要打包 `.app` 时推荐使用 XcodeGen 生成的工程。

## 测试

```bash
swift test
```

## 数据位置

命令默认保存在：

```text
~/Library/Application Support/CommandPocket/commands.json
```

悬浮窗口位置保存在 `UserDefaults`。

## 安全说明

MVP 只保存和复制命令，不会自动执行命令。检测到 JWT、Cookie、私钥或明显密码参数时，会阻止保存并提示用户。

## 项目结构

```text
Sources/CommandPocket/
├── App/
├── Models/
├── Services/
└── Views/
```

## 后续计划

- 搜索与最近使用
- 可编辑命令和拖动排序
- 变量模板，例如 `{{host}}`、`{{branch}}`
- 登录时启动
- JSON 导入/导出
- 可选 iCloud 同步

