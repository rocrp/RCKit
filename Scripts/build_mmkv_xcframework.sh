#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/../MMKV/iOS/MMKV/MMKV.xcodeproj"
SCHEME="MMKV"
CONFIGURATION="Release"

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "MMKV project not found at: $PROJECT_PATH" >&2
  exit 1
fi

BUILD_ROOT="$(mktemp -d)"
OUTPUT_PATH="$ROOT_DIR/Dependencies/MMKV.xcframework"

cleanup() {
  rm -rf "$BUILD_ROOT"
}
trap cleanup EXIT

archive() {
  local destination="$1"
  local archive_path="$2"

  xcodebuild archive \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "$destination" \
    -archivePath "$archive_path" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES
}

archive "generic/platform=iOS" "$BUILD_ROOT/MMKV-iOS"
archive "generic/platform=iOS Simulator" "$BUILD_ROOT/MMKV-iOS-Simulator"
archive "generic/platform=macOS" "$BUILD_ROOT/MMKV-macOS"

if [[ -d "$OUTPUT_PATH" ]]; then
  rm -rf "$OUTPUT_PATH"
fi

xcodebuild -create-xcframework \
  -framework "$BUILD_ROOT/MMKV-iOS.xcarchive/Products/Library/Frameworks/MMKV.framework" \
  -framework "$BUILD_ROOT/MMKV-iOS-Simulator.xcarchive/Products/Library/Frameworks/MMKV.framework" \
  -framework "$BUILD_ROOT/MMKV-macOS.xcarchive/Products/Library/Frameworks/MMKV.framework" \
  -output "$OUTPUT_PATH"

echo "MMKV.xcframework generated at: $OUTPUT_PATH"
