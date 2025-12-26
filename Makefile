SHELL := /bin/bash

.PHONY: format lint test build all build-spm test-spm generate

# Update these lines when copying this Makefile to another project.
WORKSPACE := RCKit.xcworkspace
IOS_SCHEME := RCKitDemoApp
MACOS_SCHEME := RCKitDemoMacApp

SWIFT_FILES = fd -0 -e swift -E Derived -E .build -E .git -E Tuist/.build -E '*.xcodeproj' -E '*.xcworkspace' .

format:
	$(SWIFT_FILES) | xargs -0 swift format --in-place --configuration .swift-format

lint:
	$(SWIFT_FILES) | xargs -0 swift format lint --configuration .swift-format

# SPM targets (for RCKit library)
build-spm:
	swift build

test-spm:
	swift test

# Tuist targets (for demo apps)
generate:
	tuist install
	tuist generate --no-open

test: test-spm

build: build-spm generate
	@if [ ! -d "$(WORKSPACE)" ]; then echo "error: WORKSPACE '$(WORKSPACE)' not found" >&2; exit 1; fi
	xcodebuild -workspace "$(WORKSPACE)" -scheme "$(MACOS_SCHEME)" -destination 'platform=macOS' build
	xcodebuild -workspace "$(WORKSPACE)" -scheme "$(IOS_SCHEME)" -destination 'generic/platform=iOS Simulator' build

all: format lint test
