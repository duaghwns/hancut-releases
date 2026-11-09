# 한컷(Hancut) Windows 설치 스크립트
#   PowerShell에서:  irm https://raw.githubusercontent.com/duaghwns/hancut-releases/main/install.ps1 | iex
$ErrorActionPreference = 'Stop'
$repo  = 'duaghwns/hancut-releases'
$asset = 'Hancut-windows-x64.zip'
$url   = "https://github.com/$repo/releases/latest/download/$asset"
# 설치 폴더 (HANCUT_DEST로 바꿀 수 있음): 기본은 %LOCALAPPDATA%\Programs\Hancut — 관리자 권한 필요 없음
$dest  = if ($env:HANCUT_DEST) { $env:HANCUT_DEST } else { Join-Path $env:LOCALAPPDATA 'Programs\Hancut' }

if (-not [Environment]::Is64BitOperatingSystem) { throw '한컷은 64비트 Windows가 필요합니다.' }

$tmp = Join-Path $env:TEMP ('hancut-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    Write-Host '▶ 한컷 내려받는 중… (수백 MB, 잠시 걸려요)'
    $zip = Join-Path $tmp $asset
    $ProgressPreference = 'SilentlyContinue'      # 진행 표시를 끄면 다운로드가 훨씬 빠르다
    for ($i = 1; $i -le 3; $i++) {
        try { Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing; break }
        catch { if ($i -eq 3) { throw }; Start-Sleep -Seconds 3 }
    }

    Write-Host "▶ $dest 에 설치 중…"
    Get-Process -Name Hancut -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 1
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
    Move-Item (Join-Path $tmp 'Hancut') $dest
    Get-ChildItem $dest -Recurse | Unblock-File      # 인터넷에서 받은 파일 표시 해제

    # 시작 메뉴 바로가기: WScript.Shell은 한글 파일 이름을 저장하지 못하는 경우가 있어(영문 Windows 등)
    # 영문 이름으로 만든 뒤 한글 이름으로 바꾼다. 바꾸지 못해도 설치는 계속한다.
    $menu = [Environment]::GetFolderPath('Programs')
    $tmpLnk = Join-Path $menu 'Hancut.lnk'
    $sh = (New-Object -ComObject WScript.Shell).CreateShortcut($tmpLnk)
    $sh.TargetPath = Join-Path $dest 'Hancut.exe'
    $sh.WorkingDirectory = $dest
    $sh.Description = '한컷 Hancut'
    $sh.Save()
    try { Move-Item -LiteralPath $tmpLnk -Destination (Join-Path $menu '한컷.lnk') -Force } catch { }

    Write-Host "✓ 설치 완료: $dest\Hancut.exe"
    Write-Host '  시작 메뉴에서 ''한컷''을 실행하세요.'
}
finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
