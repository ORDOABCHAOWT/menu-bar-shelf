<p align="center"><img src="docs/app-overview.png" alt="MenuBarShelf 功能预览"></p>

<h1 align="center">MenuBarShelf</h1>
<p align="center">菜单栏太挤？把仍在运行的后台应用集中找回来。</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-111111" alt="macOS 14+">
  <img src="https://img.shields.io/badge/AppKit-Native-4AAEC1" alt="Native AppKit">
  <img src="https://img.shields.io/badge/License-MIT-4AAEC1" alt="MIT License">
</p>

## 亮点

- 列出正在运行、适合从菜单栏访问的应用。
- 点击名称即可打开或唤醒对应 App。
- 原生 AppKit 菜单，自动适配明暗菜单栏。
- 默认不请求辅助功能权限，也不使用私有 API。
- 菜单栏图标不可见时，可用 `Control + Option + Command + M` 打开。

> macOS 公共 API 无法保证第三方图标永远处于最右侧。MenuBarShelf 使用最小图标和全局快捷键作为可靠后备。

## 安装与开发

从 [GitHub Releases](https://github.com/ORDOABCHAOWT/menu-bar-shelf/releases) 下载 App，或从源码构建：

```bash
swift run MenuBarShelfCoreChecks
./build_app.sh
```

构建产物位于 `dist/MenuBarShelf.app`。

## License

[MIT](LICENSE) © ORDOABCHAOWT
