#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fd -0 -e swift \
  -E Derived \
  -E .build \
  -E .git \
  -E .swiftpm \
  -E Tuist/.build \
  -E RCKit.xcodeproj \
  -E RCKit.xcworkspace \
  -E RCKitDemo.xcodeproj \
  -E RCKitDemo.xcworkspace \
  . "$ROOT_DIR" \
  | xargs -0 swift format --configuration "$ROOT_DIR/.swift-format" --in-place
