#!/usr/bin/env bash
# Puvi Split APK & Release Generation Script (Bash)
# Usage:
#   ./scripts/build_release.sh 1.0.1 2
#   ./scripts/build_release.sh 1.0.1 2 --publish

set -e

VERSION="${1:-}"
BUILD_NUMBER="${2:-}"
PUBLISH_FLAG="${3:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "═══════════════════════════════════════════════════════════════"
echo "         Puvi — Split APK & Release Builder (Puja & Vicky)     "
echo "═══════════════════════════════════════════════════════════════"

PUBSPEC_FILE="$PROJECT_ROOT/pubspec.yaml"

if [ -z "$VERSION" ]; then
  VERSION=$(grep -E '^version:' "$PUBSPEC_FILE" | sed -E 's/version:[[:space:]]*([0-9\.]+)\+?([0-9]*)/\1/')
  if [ -z "$BUILD_NUMBER" ]; then
    BUILD_NUMBER=$(grep -E '^version:' "$PUBSPEC_FILE" | sed -E 's/version:[[:space:]]*([0-9\.]+)\+?([0-9]*)/\2/')
  fi
fi

[ -z "$VERSION" ] && VERSION="1.0.0"
[ -z "$BUILD_NUMBER" ] && BUILD_NUMBER="1"

echo "• Target Release Version: v$VERSION (Build $BUILD_NUMBER)"

# Update pubspec.yaml if changed
NEW_VERSION_STR="version: $VERSION+$BUILD_NUMBER"
if ! grep -q "^version:[[:space:]]*$VERSION+$BUILD_NUMBER" "$PUBSPEC_FILE"; then
  sed -i.bak -E "s/^version:[[:space:]]*[0-9\.]+\+?[0-9]*/$NEW_VERSION_STR/" "$PUBSPEC_FILE"
  rm -f "$PUBSPEC_FILE.bak"
  echo "✓ Updated pubspec.yaml with $NEW_VERSION_STR"
fi

RELEASE_DIR="$PROJECT_ROOT/releases/v$VERSION"
mkdir -p "$RELEASE_DIR"

echo -e "\n[1/4] Resolving Flutter dependencies..."
flutter pub get

echo -e "\n[2/4] Building Split-per-ABI APKs (arm64-v8a, armeabi-v7a, x86_64)..."
flutter build apk --split-per-abi

echo -e "\n[3/4] Building Universal Release APK..."
flutter build apk

echo -e "\n[4/4] Copying and packaging releases into releases/v$VERSION/..."
SRC_DIR="$PROJECT_ROOT/build/app/outputs/flutter-apk"
CHECKSUM_FILE="$RELEASE_DIR/checksums.txt"
> "$CHECKSUM_FILE"

copy_and_hash() {
  local src_name="$1"
  local dst_name="$2"
  local src_path="$SRC_DIR/$src_name"
  local dst_path="$RELEASE_DIR/$dst_name"

  if [ -f "$src_path" ]; then
    cp -f "$src_path" "$dst_path"
    local hash
    if command -v sha256sum &> /dev/null; then
      hash=$(sha256sum "$dst_path" | awk '{print $1}')
    else
      hash=$(shasum -a 256 "$dst_path" | awk '{print $1}')
    fi
    local size
    size=$(du -h "$dst_path" | awk '{print $1}')
    echo "$hash  $dst_name  ($size)" >> "$CHECKSUM_FILE"
    echo "  ✓ $dst_name ($size)"
  else
    echo "  ! Warning: $src_name not found."
  fi
}

copy_and_hash "app-arm64-v8a-release.apk" "puvi-v$VERSION-arm64-v8a.apk"
copy_and_hash "app-armeabi-v7a-release.apk" "puvi-v$VERSION-armeabi-v7a.apk"
copy_and_hash "app-x86_64-release.apk" "puvi-v$VERSION-x86_64.apk"
copy_and_hash "app-release.apk" "puvi-v$VERSION-universal.apk"

NOTES_FILE="$RELEASE_DIR/release_notes.md"
cat << EOF > "$NOTES_FILE"
# Puvi v$VERSION ($NEW_VERSION_STR)

### What's New 💕
- Real-time love shower notifications and simultaneous theme melody playback.
- Alive "Send Love" hold button with +1,000 celebration overlay.
- "Next Chapter" countdown clock for monthly, half-yearly & yearly anniversaries.
- In-app auto-update checker and one-click package installer.

### Downloads
- **puvi-v$VERSION-arm64-v8a.apk** (Recommended for modern Android phones)
- **puvi-v$VERSION-armeabi-v7a.apk** (For older 32-bit Android phones)
- **puvi-v$VERSION-universal.apk** (Universal installer compatible with all devices)
EOF

echo "✓ Generated release notes template at $NOTES_FILE"
echo "✓ Generated SHA256 checksums at $CHECKSUM_FILE"

if [ "$PUBLISH_FLAG" == "--publish" ]; then
  if command -v gh &> /dev/null; then
    echo -e "\nPublishing release v$VERSION to GitHub (imvicky69/puvi-app)..."
    gh release create "v$VERSION" "$RELEASE_DIR"/*.apk --title "Puvi v$VERSION 💕" --notes-file "$NOTES_FILE"
    echo "✓ Successfully published release to GitHub!"
  else
    echo "! GitHub CLI (gh) not found on PATH. Please upload files manually."
  fi
fi

echo "═══════════════════════════════════════════════════════════════"
echo "  ✓ All split APKs generated successfully in: releases/v$VERSION/"
echo "═══════════════════════════════════════════════════════════════"
