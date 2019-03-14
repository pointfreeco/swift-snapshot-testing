xcodeproj:
	swift run xcodegen

test-linux:
	docker build --tag snapshot-testing . \
		&& docker run --rm snapshot-testing

test-macos:
	set -o pipefail && \
	xcodebuild test \
		-scheme SnapshotTesting_macOS \
		-destination platform="macOS" \

test-ios:
	set -o pipefail && \
	xcodebuild test \
		-scheme SnapshotTesting_iOS \
		-destination platform="iOS Simulator,name=iPhone XR,OS=12.1" \

test-swift:
	swift test

test-tvos:
	set -o pipefail && \
	xcodebuild test \
		-scheme SnapshotTesting_tvOS \
		-destination platform="tvOS Simulator,name=Apple TV 4K,OS=12.1" \

test-all: test-linux test-macos test-ios
