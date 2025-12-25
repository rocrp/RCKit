SHELL := /bin/bash

.PHONY: format lint test build all

# Update these lines when copying this Makefile to another project.
WORKSPACE := RCKit.xcworkspace
IOS_SCHEME := RCKitDemoApp
MACOS_SCHEME := RCKitDemoMacApp
TEST_SCHEME := RCKitTests

SWIFT_FILES = fd -0 -e swift -E Derived -E .build -E .git -E Tuist/.build -E '*.xcodeproj' -E '*.xcworkspace' .

format:
	$(SWIFT_FILES) | xargs -0 swift format --in-place --configuration .swift-format

lint:
	$(SWIFT_FILES) | xargs -0 swift format lint --configuration .swift-format

test:
	@if [ -z "$(TEST_SCHEME)" ]; then echo "error: TEST_SCHEME not set; edit Makefile or pass TEST_SCHEME=..." >&2; exit 1; fi
	tuist generate --no-open
	@if [ ! -d "$(WORKSPACE)" ]; then echo "error: WORKSPACE '$(WORKSPACE)' not found; edit Makefile or pass WORKSPACE=..." >&2; exit 1; fi
	tuist test "$(TEST_SCHEME)" --no-selective-testing --platform macOS

build:
	tuist generate --no-open
	@if [ ! -d "$(WORKSPACE)" ]; then echo "error: WORKSPACE '$(WORKSPACE)' not found; edit Makefile or pass WORKSPACE=..." >&2; exit 1; fi
	xcodebuild -workspace "$(WORKSPACE)" -scheme "$(MACOS_SCHEME)" -destination 'platform=macOS' build
	xcodebuild -workspace "$(WORKSPACE)" -scheme "$(IOS_SCHEME)" -destination 'generic/platform=iOS Simulator' build

all: format lint test
