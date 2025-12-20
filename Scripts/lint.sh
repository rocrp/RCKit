#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fd -0 -e swift \
  -E Derived \
  -E .build \
  -E .git \
  -E Tuist/.build \
  -E RCKit.xcodeproj \
  -E RCKit.xcworkspace \
  . "$ROOT_DIR" \
  | xargs -0 swift format lint --configuration "$ROOT_DIR/.swift-format"
