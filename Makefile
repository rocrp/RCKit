SHELL := /bin/bash

.PHONY: format lint test all

format:
	./Scripts/format.sh

lint:
	./Scripts/lint.sh

test:
	tuist test RCKitTests --no-selective-testing

all: format lint test
