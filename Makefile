test-linux:
	docker build --tag snapshot-testing . \
		&& docker run --rm snapshot-testing

test-mac:
	xcodebuild test \
		-scheme SnapshotTesting-Package \
		-destination platform="macOS" \
		| xcpretty

test-ios:
	xcodebuild test \
		-scheme SnapshotTesting-Package \
		-destination platform="iOS Simulator,name=iPhone 8,OS=11.0" \
		| xcpretty

test-all: test-linux test-mac test-ios
