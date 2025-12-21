SHELL := /bin/bash

.PHONY: format lint test build all

format:
	./Scripts/format.sh

lint:
	./Scripts/lint.sh

test:
	tuist test RCKitTests --no-selective-testing

build:
	tuist generate --no-open
	xcodebuild -workspace RCKit.xcworkspace -scheme RCKitDemo -destination 'platform=macOS' build
	xcodebuild -workspace RCKit.xcworkspace -scheme RCKitDemo -destination 'generic/platform=iOS Simulator' build

all: format lint test
