# DSH Desktop

Launch the [DeepSeek Harness (DSH)](https://github.com/deepseek-ai/deepseek-harness) web app as a desktop window on Windows — no terminal, no browser.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows-0078D6.svg)

[中文说明](README.zh.md)

## Features

- **One-click launch** — double-click `DSH.vbs` and the app opens in its own window.
- **Instant window** — a splash screen appears immediately while the DSH server boots in the background, then redirects automatically.
- **Chrome-free window** — the UI runs in a Microsoft Edge "app mode" window (no address bar, no tabs).
- **Clean shutdown** — closing the window stops the background server, leaving no lingering process.
- **Single instance** — launching again while it is open reuses the running server and opens another window.
- **Warm start** — reuses one persistent Edge profile, so subsequent launches are faster and produce no leftover profile folders.

## Requirements

- Windows 10 / 11
- [Node.js](https://nodejs.org/) (>= 22) available on `PATH`
- Microsoft Edge (preinstalled on Windows 10/11)

## Install

1. Build the bundled app. This installs the `dsh` web app into `app/` and prunes it to a minimal runtime footprint:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build.ps1
   ```

   or, if npm is on your `PATH`:

   ```powershell
   npm run build
   ```

2. Launch the app:

   ```
   DSH.vbs
   ```

   Optionally create a desktop shortcut to `DSH.vbs` and set its icon to `icon.ico`.

## How it works

1. `DSH.vbs` hides the console window and runs `launcher.ps1` via `powershell.exe`.
2. `launcher.ps1` starts the bundled `dsh web` server (`app/`) on port `3081` and opens `splash.html` in an Edge app-mode window.
3. `splash.html` polls the server until it is ready, then redirects to it.
4. When the window closes, `launcher.ps1` stops the server and cleans up its state.

The DSH data (sessions, settings, credentials) lives in `%USERPROFILE%\.dsh`, shared with the regular `dsh web` command.

## Configuration

| Setting | Location | Default |
| --- | --- | --- |
| Port | `$port` at the top of `launcher.ps1`, passed to `splash.html` via `?port=` | `3081` |

## Project structure

```
dsh-desktop/
├── DSH.vbs              double-click entry point
├── launcher.ps1         launch logic
├── splash.html          splash screen
├── icon.ico             app icon
├── scripts/
│   └── build.ps1        installs and prunes the bundled app/
├── tools/
│   ├── generate-icon.ps1
│   └── prune-app.ps1
└── app/                 built by scripts/build.ps1 (git-ignored)
```

## License

[MIT](LICENSE)
