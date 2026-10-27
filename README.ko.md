<div align="center">

<img src="Resources/AppIcon.png" width="96" height="96" alt="DockMin 아이콘">

# DockMin

**macOS Dock에서 Windows 작업 표시줄처럼: 클릭하여 창을 최소화 및 복원.**

<p align="center">
  오픈소스 및 완전 무료 · macOS 14 이상 지원 · 초경량 (약 1 MB)
  <br><br>
  <a href="https://github.com/fatthreeking/DockMin/releases/latest">다운로드&nbsp;&rsaquo;</a>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <a href="#3-소스-코드에서-빌드">소스 코드에서 빌드&nbsp;&rsaquo;</a>
  <br><br>
  <a href="README.md">English</a>&nbsp;·&nbsp;<a href="README.zh.md">简体中文</a>&nbsp;·&nbsp;<a href="README.ja.md">日本語</a>&nbsp;·&nbsp;한국어&nbsp;·&nbsp;<a href="README.es.md">Español</a>&nbsp;·&nbsp;<a href="README.de.md">Deutsch</a>
</p>

<br>

<img src="Resources/demo.gif" width="700" alt="DockMin 데모">

</div>

<br><br>

## 주요 기능

<table width="100%">
  <tr>
    <td width="50%" valign="top">
      <img src="Resources/icons/toggle.svg" width="28" height="28" alt=""><br><br>
      <strong>클릭하여 전환.</strong><br>
      <small>활성 앱의 Dock 아이콘을 클릭하여 최소화하고, 다시 클릭하여 복원.</small>
    </td>
    <td width="50%" valign="top">
      <img src="Resources/icons/display.svg" width="28" height="28" alt=""><br><br>
      <strong>멀티 모니터 지원.</strong><br>
      <small>외부 디스플레이 창도 화면 간 튕김 없이 제자리에 유지.</small>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <img src="Resources/icons/speed.svg" width="28" height="28" alt=""><br><br>
      <strong>초경량 순수 Swift.</strong><br>
      <small>약 1 MB의 초소형 크기, 외부 라이브러리 없음. 유휴 CPU 점유율 약 0%.</small>
    </td>
    <td width="50%" valign="top">
      <img src="Resources/icons/silent.svg" width="28" height="28" alt=""><br><br>
      <strong>완벽한 무음 상주.</strong><br>
      <small>메뉴 막대나 추가 Dock 아이콘 없음. 네트워크 요청 없는 100% 오프라인.</small>
    </td>
  </tr>
</table>

<br><br>

## 설치 방법

### 1. DMG 드래그 앤 드롭 (권장)

**[DockMin.dmg](https://github.com/fatthreeking/DockMin/releases/latest)**를 다운로드하고 Applications(응용 프로그램) 폴더로 드래그하세요.  
최초 실행 시 **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용**에서 허용해 주세요.

보안 경고("손상되었기 때문에 열 수 없습니다" 또는 "개발자를 확인할 수 없기 때문에 열 수 없습니다")로 열리지 않는 경우 터미널에서 실행:

```sh
xattr -cr /Applications/DockMin.app
```

### 2. Homebrew

터미널에서 실행:

```sh
brew install --cask fatthreeking/tap/dockmin
```

### 3. 소스 코드에서 빌드

터미널에서 실행:

```sh
git clone https://github.com/fatthreeking/DockMin.git
cd DockMin
make install
```

### 완전 제거

백그라운드 실행 중 응용 프로그램 폴더에서 **`DockMin.app`을 다시 더블 클릭**하면 관리 창이 나타나며, **종료** 또는 **완전 제거**를 바로 선택할 수 있습니다.

또는 터미널에서 실행:

```sh
make uninstall
```

<br><br>

<div align="center">

<img src="Resources/AppIcon.png" width="48" height="48" alt="DockMin 아이콘">
<br>
<sub>코드는 MIT 라이선스를 따릅니다. DockMin 명칭 및 아이콘은 포함되지 않으므로 포크 버전에서는 별도 식별자를 사용해야 합니다. <a href="LICENSE">LICENSE</a>를 참조하세요.</sub>
<br>
<sub>Designed and built by <a href="https://x.com/fatthreeking">Fisher</a>.</sub>

</div>
