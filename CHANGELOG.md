# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-08-19

### Added

- `DSH.vbs` double-click entry point (hidden console, relocatable folder).
- `launcher.ps1` launch logic (server start, splash-first window, clean shutdown, single instance).
- `splash.html` startup screen with automatic redirect once the server is ready.
- `icon.ico` app icon plus `tools/generate-icon.ps1` to regenerate it.
- `scripts/build.ps1` to install and prune the bundled `dsh` app.
- `tools/prune-app.ps1` to strip the bundled `app/` down to a minimal win32-x64 runtime.
- Documentation (`README.md`, `README.zh.md`), `LICENSE`, and `.gitignore`.
