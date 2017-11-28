test-linux:
	docker build --tag snapshot-testing . \
		&& docker run --rm snapshot-testing

test-macos:
	set -o pipefail && \
	xcodebuild test \
		-scheme SnapshotTesting-Package \
		-destination platform="macOS" \
		| xcpretty

test-ios:
	set -o pipefail && \
	xcodebuild test \
		-scheme SnapshotTesting-Package \
		-destination platform="iOS Simulator,name=iPhone 8,OS=11.0" \
		| xcpretty

test-swift:
	swift test

test-all: test-linux test-mac test-ios
