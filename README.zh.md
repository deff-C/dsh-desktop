# DSH Desktop（DSH 桌面版）

把 [DeepSeek Harness (DSH)](https://github.com/deepseek-ai/deepseek-harness) 的 Web 应用打包成 Windows 桌面窗口——无需打开终端，也无需手动打开浏览器。

[English](README.md)

## 特性

- **双击即开** — 双击 `DSH.vbs`，应用在独立窗口打开。
- **秒开体验** — 先立即弹出启动页，DSH 服务在后台启动，就绪后自动跳转进入。
- **无边框窗口** — 界面运行在 Microsoft Edge 的“应用模式”窗口（无地址栏、无标签页）。
- **干净退出** — 关闭窗口即停止后台服务，不留残留进程。
- **单实例** — 运行期间再次双击会复用同一服务，只多开一个窗口。
- **热启动** — 复用一个固定的 Edge 配置目录，后续打开更快，也不再产生临时配置目录。

## 环境要求

- Windows 10 / 11
- [Node.js](https://nodejs.org/)（>= 22），已加入 `PATH`
- Microsoft Edge（Windows 10/11 自带）

## 安装

1. 构建内置应用：把 `dsh` Web 应用安装到 `app/` 并精简到最小运行集：

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build.ps1
   ```

   或（若 npm 已在 `PATH` 中）：

   ```powershell
   npm run build
   ```

2. 启动：

   ```
   DSH.vbs
   ```

   可选：为 `DSH.vbs` 创建桌面快捷方式，并把图标设为 `icon.ico`。

## 工作原理

1. `DSH.vbs` 隐藏控制台窗口，通过 `powershell.exe` 运行 `launcher.ps1`。
2. `launcher.ps1` 在端口 `3081` 启动内置的 `dsh web` 服务（`app/`），并在 Edge 应用模式窗口中打开 `splash.html`。
3. `splash.html` 轮询服务直至就绪，然后自动跳转进入。
4. 关闭窗口后，`launcher.ps1` 停止服务并清理运行状态。

DSH 的数据（会话、设置、凭据）仍保存在 `%USERPROFILE%\.dsh`，与普通 `dsh web` 命令共享。

## 配置

| 设置项 | 位置 | 默认值 |
| --- | --- | --- |
| 端口 | `launcher.ps1` 顶部的 `$port`，并通过 `?port=` 传给 `splash.html` | `3081` |

## 目录结构

```
dsh-desktop/
├── DSH.vbs              双击启动入口
├── launcher.ps1         启动逻辑
├── splash.html          启动页
├── icon.ico             应用图标
├── scripts/
│   └── build.ps1        安装并精简内置的 app/
├── tools/
│   ├── generate-icon.ps1
│   └── prune-app.ps1
└── app/                 由 scripts/build.ps1 构建（已 git-ignore）
```

## 许可证

[MIT](LICENSE)
