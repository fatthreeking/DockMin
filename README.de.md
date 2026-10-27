<div align="center">

<img src="Resources/AppIcon.png" width="96" height="96" alt="DockMin Icon">

# DockMin

**Klicken, um Fenster im macOS Dock zu minimieren – genau wie in der Windows-Taskleiste.**

<p align="center">
  Kostenlos und Open Source · Für macOS 14 und neuer · Leicht (~1 MB)
  <br><br>
  <a href="https://github.com/fatthreeking/DockMin/releases/latest">Herunterladen&nbsp;&rsaquo;</a>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <a href="#3-aus-dem-quellcode-bauen">Aus dem Quellcode bauen&nbsp;&rsaquo;</a>
  <br><br>
  <a href="README.md">English</a>&nbsp;·&nbsp;<a href="README.zh.md">简体中文</a>&nbsp;·&nbsp;<a href="README.ja.md">日本語</a>&nbsp;·&nbsp;<a href="README.ko.md">한국어</a>&nbsp;·&nbsp;<a href="README.es.md">Español</a>&nbsp;·&nbsp;Deutsch
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
      <strong>Klick zum Umschalten.</strong><br>
      <small>Klicke auf das Dock-Symbol der aktiven App zum Minimieren; klicke erneut zum Wiederherstellen.</small>
    </td>
    <td width="50%" valign="top">
      <img src="Resources/icons/display.svg" width="28" height="28" alt=""><br><br>
      <strong>Multi-Monitor-Unterstützung.</strong><br>
      <small>Fenster bleiben auf ihren jeweiligen Bildschirmen ohne störendes Springen.</small>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <img src="Resources/icons/speed.svg" width="28" height="28" alt=""><br><br>
      <strong>Ultra-leicht und Pure Swift.</strong><br>
      <small>Nur ~1 MB groß, keine externen Bibliotheken. Nahezu 0% CPU-Last im Leerlauf.</small>
    </td>
    <td width="50%" valign="top">
      <img src="Resources/icons/silent.svg" width="28" height="28" alt=""><br><br>
      <strong>Lautloser Hintergrunddienst.</strong><br>
      <small>Kein Menüleisten-Symbol, kein zusätzliches Dock-Icon. 100% offline.</small>
    </td>
  </tr>
</table>

<br><br>

## Installation

### 1. Direkter Download (Empfohlen)

Lade **[DockMin.dmg](https://github.com/fatthreeking/DockMin/releases/latest)** herunter und ziehe `DockMin.app` in den Ordner Programme.  
Aktiviere DockMin beim ersten Start unter **Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen**.

Falls macOS die App blockiert (z. B. „ist beschädigt und kann nicht geöffnet werden“ oder „Entwickler kann nicht verifiziert werden“), im Terminal ausführen:

```sh
xattr -cr /Applications/DockMin.app
```

### 2. Homebrew

Im Terminal ausführen:

```sh
brew install --cask fatthreeking/tap/dockmin
```

### 3. Aus dem Quellcode bauen

Im Terminal ausführen:

```sh
git clone https://github.com/fatthreeking/DockMin.git
cd DockMin
make install
```

### Deinstallation

Während DockMin im Hintergrund läuft, **doppelklicke erneut auf `DockMin.app`** im Ordner Programme, um den Verwaltungsdialog zu öffnen und **Beenden** oder **Vollständig deinstallieren** auszuwählen.

Oder im Terminal ausführen:

```sh
make uninstall
```

<br><br>

<div align="center">

<img src="Resources/AppIcon.png" width="48" height="48" alt="DockMin Icon">
<br>
<sub>Der Code steht unter der MIT-Lizenz. Der Name und das Icon von DockMin sind nicht enthalten, Forks benötigen eigene. Siehe <a href="LICENSE">LICENSE</a>.</sub>
<br>
<sub>Entworfen und entwickelt von <a href="https://x.com/fatthreeking">Fisher</a>.</sub>

</div>
