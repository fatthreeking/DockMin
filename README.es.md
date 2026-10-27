<div align="center">

<img src="Resources/AppIcon.png" width="96" height="96" alt="Icono de DockMin">

# DockMin

**Minimiza ventanas desde el Dock de macOS como en la barra de tareas de Windows.**

<p align="center">
  Gratuito y de código abierto · Para macOS 14 y posteriores · Ligero (~1 MB)
  <br><br>
  <a href="https://github.com/fatthreeking/DockMin/releases/latest">Descargar&nbsp;&rsaquo;</a>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <a href="#3-compilar-desde-el-código-fuente">Compilar desde la fuente&nbsp;&rsaquo;</a>
  <br><br>
  <a href="README.md">English</a>&nbsp;·&nbsp;<a href="README.zh.md">简体中文</a>&nbsp;·&nbsp;<a href="README.ja.md">日本語</a>&nbsp;·&nbsp;<a href="README.ko.md">한국어</a>&nbsp;·&nbsp;Español&nbsp;·&nbsp;<a href="README.de.md">Deutsch</a>
</p>

<br>

<img src="Resources/demo.gif" width="700" alt="Demostración de DockMin">

</div>

<br><br>

## Características destacadas

<table width="100%">
  <tr>
    <td width="50%" valign="top">
      <img src="Resources/icons/toggle.svg" width="28" height="28" alt=""><br><br>
      <strong>Alternar con un clic.</strong><br>
      <small>Haz clic en el icono del Dock activo para minimizarla; haz clic de nuevo para restaurarla.</small>
    </td>
    <td width="50%" valign="top">
      <img src="Resources/icons/display.svg" width="28" height="28" alt=""><br><br>
      <strong>Soporte multimonitor.</strong><br>
      <small>Las ventanas se mantienen en sus respectivas pantallas sin saltos entre monitores.</small>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <img src="Resources/icons/speed.svg" width="28" height="28" alt=""><br><br>
      <strong>Ultraligero y Swift puro.</strong><br>
      <small>Solo ~1 MB, sin dependencias externas. Casi 0% de uso de CPU en reposo.</small>
    </td>
    <td width="50%" valign="top">
      <img src="Resources/icons/silent.svg" width="28" height="28" alt=""><br><br>
      <strong>Totalmente silencioso.</strong><br>
      <small>Sin iconos en la barra de menús ni desorden en el Dock. 100% offline.</small>
    </td>
  </tr>
</table>

<br><br>

## Instalación

### 1. Descarga directa (Recomendado)

Descarga **[DockMin.dmg](https://github.com/fatthreeking/DockMin/releases/latest)** y arrastra `DockMin.app` a Aplicaciones.  
Activa el permiso en **Ajustes del Sistema → Privacidad y seguridad → Accesibilidad** en el primer inicio.

Si macOS bloquea la apertura (p. ej., «está dañado y no se puede abrir» o «no se puede verificar el desarrollador»), ejecuta en la Terminal:

```sh
xattr -cr /Applications/DockMin.app
```

### 2. Homebrew

Ejecuta en la Terminal:

```sh
brew install --cask fatthreeking/tap/dockmin
```

### 3. Compilar desde el código fuente

Ejecuta en la Terminal:

```sh
git clone https://github.com/fatthreeking/DockMin.git
cd DockMin
make install
```

### Desinstalación

Mientras DockMin se ejecuta en segundo plano, **haz doble clic de nuevo en `DockMin.app`** en Aplicaciones para abrir el diálogo de gestión y elegir **Salir** o **Desinstalar por completo**.

O ejecuta en la Terminal:

```sh
make uninstall
```

<br><br>

<div align="center">

<img src="Resources/AppIcon.png" width="48" height="48" alt="Icono de DockMin">
<br>
<sub>El código está bajo licencia MIT. El nombre y el icono de DockMin no están incluidos, por lo que las bifurcaciones necesitan los suyos propios. Consulta <a href="LICENSE">LICENSE</a>.</sub>
<br>
<sub>Diseñado y desarrollado por <a href="https://x.com/fatthreeking">Fisher</a>.</sub>

</div>
