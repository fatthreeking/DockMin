<div align="center">

<img src="Resources/AppIcon.png" width="96" height="96" alt="DockMin Icon">

# DockMin

**Click to minimize windows from the macOS Dock — just like on Windows.**

<p align="center">
  Free & Open Source · For macOS 14 and later · Lightweight (~1 MB)
  <br><br>
  <a href="https://github.com/fatthreeking/DockMin/releases/latest">Download&nbsp;&rsaquo;</a>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <a href="#3-build-from-source">Build from source&nbsp;&rsaquo;</a>
  <br><br>
  English&nbsp;·&nbsp;<a href="README.zh.md">简体中文</a>&nbsp;·&nbsp;<a href="README.ja.md">日本語</a>&nbsp;·&nbsp;<a href="README.ko.md">한국어</a>&nbsp;·&nbsp;<a href="README.es.md">Español</a>&nbsp;·&nbsp;<a href="README.de.md">Deutsch</a>
</p>

<br>

<img src="Resources/demo.gif" width="700" alt="DockMin Demo">

</div>

<br><br>

## Highlights

<table width="100%">
  <tr>
    <td width="50%" valign="top">
      <img src="Resources/icons/toggle.svg" width="28" height="28" alt=""><br><br>
      <strong>Click to toggle.</strong><br>
      <small>Click once to open, click again to minimize.</small>
    </td>
    <td width="50%" valign="top">
      <img src="Resources/icons/display.svg" width="28" height="28" alt=""><br><br>
      <strong>Multi-monitor safe.</strong><br>
      <small>Windows stay on their respective screens.</small>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <img src="Resources/icons/speed.svg" width="28" height="28" alt=""><br><br>
      <strong>Pure Swift & light.</strong><br>
      <small>Only ~1 MB, zero dependencies. Virtually 0% CPU at idle.</small>
    </td>
    <td width="50%" valign="top">
      <img src="Resources/icons/silent.svg" width="28" height="28" alt=""><br><br>
      <strong>Completely silent.</strong><br>
      <small>No menu bar clutter, no extra Dock icons.</small>
    </td>
  </tr>
</table>

<br><br>

## Installation

### 1. Direct Download (Recommended)

Download **[DockMin.dmg](https://github.com/fatthreeking/DockMin/releases/latest)** and drag `DockMin.app` to Applications.  
Enable DockMin in **System Settings → Privacy & Security → Accessibility** on first launch.

If blocked by macOS security (e.g. "is damaged and can’t be opened" or "cannot be opened because the developer cannot be verified"), run in Terminal:

```sh
xattr -cr /Applications/DockMin.app
```

### 2. Homebrew

Run in Terminal:

```sh
brew install --cask fatthreeking/tap/dockmin
```

### 3. Build from Source

Run in Terminal:

```sh
git clone https://github.com/fatthreeking/DockMin.git
cd DockMin
make install
```

### Uninstall

While DockMin is running in the background, **double-click `DockMin.app` again** in Applications to bring up the management dialog, where you can choose **Quit DockMin** or **Uninstall** (automatically removes the LaunchAgent, resets Accessibility permissions, and moves the app to Trash).

Or run in Terminal:

```sh
make uninstall
```

<br><br>

<div align="center">

<img src="Resources/AppIcon.png" width="48" height="48" alt="DockMin Icon">
<br>
<sub>The code is MIT licensed. The DockMin name and icon are not, so forks need their own. See <a href="LICENSE">LICENSE</a>.</sub>
<br>
<sub>Designed and built by <a href="https://x.com/fatthreeking">Fisher</a>.</sub>

</div>
