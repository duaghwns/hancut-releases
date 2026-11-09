#!/bin/bash
# 한컷(Hancut) 설치 스크립트
#   curl -fsSL https://raw.githubusercontent.com/duaghwns/hancut-releases/main/install.sh | bash
set -euo pipefail

REPO="duaghwns/hancut-releases"
ASSET="Hancut-macos-arm64.zip"
URL="https://github.com/$REPO/releases/latest/download/$ASSET"

say() { printf '\033[1m%s\033[0m\n' "$*"; }
fail() { printf '\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

[ "$(uname -s)" = "Darwin" ] || fail "한컷은 현재 macOS만 지원합니다."
[ "$(uname -m)" = "arm64" ] || fail "Apple Silicon Mac(M1 이상)이 필요합니다."

if [ -n "${HANCUT_DEST:-}" ]; then DEST="$HANCUT_DEST"; mkdir -p "$DEST"     # 설치 위치 지정 (선택)
elif [ -w /Applications ]; then DEST="/Applications"
else DEST="$HOME/Applications"; mkdir -p "$DEST"; fi

say "▶ 한컷 내려받는 중… (약 320MB)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
curl -fL --retry 3 --retry-delay 3 --progress-bar -o "$TMP/$ASSET" "$URL"

say "▶ $DEST 에 설치 중…"
ditto -x -k "$TMP/$ASSET" "$TMP"
if [ -d "$DEST/Hancut.app" ]; then
  pkill -f "$DEST/Hancut.app/Contents/MacOS/Hancut" 2>/dev/null || true
  rm -rf "$DEST/Hancut.app"
fi
mv "$TMP/Hancut.app" "$DEST/"
xattr -dr com.apple.quarantine "$DEST/Hancut.app" 2>/dev/null || true

# 촬영 시각·AF 위치를 읽는 데 exiftool이 필요하다
if ! command -v exiftool >/dev/null 2>&1 && [ ! -x /opt/homebrew/bin/exiftool ]; then
  if command -v brew >/dev/null 2>&1; then
    say "▶ exiftool 설치 중… (촬영 시각·AF 위치 읽기용)"
    brew install exiftool
  else
    printf '\033[33m! exiftool이 없어요. 촬영 시각과 AF 위치를 읽으려면 https://exiftool.org 에서 설치해 주세요.\033[0m\n'
  fi
fi

say "✓ 설치 완료: $DEST/Hancut.app"
echo "  Launchpad나 응용 프로그램 폴더에서 '한컷'을 실행하세요."
