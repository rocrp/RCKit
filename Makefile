SHELL := /bin/bash

.PHONY: format lint test build all

SWIFT_FILES = fd -0 -e swift -E Derived -E .build -E .git -E Tuist/.build -E RCKit.xcodeproj -E RCKit.xcworkspace .

format:
	$(SWIFT_FILES) | xargs -0 swift format --in-place --configuration .swift-format

lint:
	$(SWIFT_FILES) | xargs -0 swift format lint --configuration .swift-format

test:
	tuist test RCKitTests --no-selective-testing --platform macOS

build:
	tuist generate --no-open
	xcodebuild -workspace RCKit.xcworkspace -scheme RCKitDemo -destination 'platform=macOS' build
	xcodebuild -workspace RCKit.xcworkspace -scheme RCKitDemo -destination 'generic/platform=iOS Simulator' build

all: format lint test
