xcodeproj:
	swift package generate-xcodeproj --xcconfig-overrides=Development.xcconfig

test-linux:
	docker build --tag snapshot-testing . \
		&& docker run --rm snapshot-testing

test-macos:
	set -o pipefail && \
	xcodebuild test \
		-scheme SnapshotTesting-Package \
		-destination platform="macOS" \

test-ios:
	set -o pipefail && \
	xcodebuild test \
		-scheme SnapshotTesting-Package \
		-destination platform="iOS Simulator,name=iPhone XR,OS=12.0" \

test-swift:
	swift test

test-all: test-linux test-mac test-ios
