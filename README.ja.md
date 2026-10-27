<div align="center">

<img src="Resources/AppIcon.png" width="96" height="96" alt="DockMin アイコン">

# DockMin

**macOS の Dock で Windows のような「クリックで最小化・復元」を実現。**

<p align="center">
  オープンソース・完全無料 · macOS 14 以降対応 · 超軽量（約 1 MB）
  <br><br>
  <a href="https://github.com/fatthreeking/DockMin/releases/latest">ダウンロード&nbsp;&rsaquo;</a>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <a href="#3-ソースコードからビルド">ソースコードからビルド&nbsp;&rsaquo;</a>
  <br><br>
  <a href="README.md">English</a>&nbsp;·&nbsp;<a href="README.zh.md">简体中文</a>&nbsp;·&nbsp;日本語&nbsp;·&nbsp;<a href="README.ko.md">한국어</a>&nbsp;·&nbsp;<a href="README.es.md">Español</a>&nbsp;·&nbsp;<a href="README.de.md">Deutsch</a>
</p>

<br>

<img src="Resources/demo.gif" width="700" alt="DockMin デモ">

</div>

<br><br>

## 主な特徴

<table width="100%">
  <tr>
    <td width="50%" valign="top">
      <img src="Resources/icons/toggle.svg" width="28" height="28" alt=""><br><br>
      <strong>クリックで切り替え。</strong><br>
      <small>最前面アプリの Dock アイコンをクリックして最小化、再クリックで復元。</small>
    </td>
    <td width="50%" valign="top">
      <img src="Resources/icons/display.svg" width="28" height="28" alt=""><br><br>
      <strong>マルチモニター対応。</strong><br>
      <small>外部ディスプレイのウィンドウも画面をまたがずに自然に維持。</small>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <img src="Resources/icons/speed.svg" width="28" height="28" alt=""><br><br>
      <strong>超軽量＆Pure Swift。</strong><br>
      <small>ファイルサイズわずか約 1 MB、外部依存関係ゼロ。アイドル時 CPU 使用率ほぼ 0%。</small>
    </td>
    <td width="50%" valign="top">
      <img src="Resources/icons/silent.svg" width="28" height="28" alt=""><br><br>
      <strong>完全ステルス動作。</strong><br>
      <small>メニューバーや追加 Dock アイコンなし。通信ゼロの 100% オフライン。</small>
    </td>
  </tr>
</table>

<br><br>

## インストール方法

### 1. DMG によるインストール（推奨）

**[DockMin.dmg](https://github.com/fatthreeking/DockMin/releases/latest)** をダウンロードし、「アプリケーション」フォルダにドラッグしてください。  
初回起動時に、**システム設定 → プライバシーとセキュリティ → アクセシビリティ** で許可を有効にしてください。

セキュリティ警告（「壊れているため開けません」または「開発元を検証できないため開けません」など）が表示される場合、ターミナルで実行：

```sh
xattr -cr /Applications/DockMin.app
```

### 2. Homebrew

ターミナルで実行：

```sh
brew install --cask fatthreeking/tap/dockmin
```

### 3. ソースコードからビルド

ターミナルで実行：

```sh
git clone https://github.com/fatthreeking/DockMin.git
cd DockMin
make install
```

### アンインストール

バックグラウンド動作中に「アプリケーション」内の **`DockMin.app` をもう一度ダブルクリック**すると管理ダイアログが表示され、**「DockMin を終了」**または**「完全アンインストール」**を選択できます。

またはターミナルで実行：

```sh
make uninstall
```

<br><br>

<div align="center">

<img src="Resources/AppIcon.png" width="48" height="48" alt="DockMin アイコン">
<br>
<sub>コードは MIT ライセンスです。DockMin の名称およびアイコンは含まれないため、フォーク版では独自のものをご使用ください。<a href="LICENSE">LICENSE</a> を参照。</sub>
<br>
<sub>Designed and built by <a href="https://x.com/fatthreeking">Fisher</a>.</sub>

</div>
