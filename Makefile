SHELL := /bin/bash

.PHONY: format lint test test-spm build build-spm all

format:
	./Scripts/format.sh

lint:
	./Scripts/lint.sh

test-spm:
	swift test

test:
	tuist test RCKitDemoTests --no-selective-testing

build-spm:
	swift build

build:
	tuist generate --no-open
	xcodebuild -workspace RCKitDemo.xcworkspace -scheme RCKitDemo -destination 'platform=macOS' build
	xcodebuild -workspace RCKitDemo.xcworkspace -scheme RCKitDemo -destination 'generic/platform=iOS Simulator' build

all: format lint test-spm test
