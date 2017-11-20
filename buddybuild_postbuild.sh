#!/usr/bin/env bash

bundle install --quiet
mkdir -p buddybuild_artifacts/SwiftTests

xcodebuild test -scheme SnapshotTesting-Package -destination platform="macOS" | bundle exec xcpretty -r junit -o buddybuild_artifacts/SwiftTests/output-mac.xml

xcodebuild test -scheme SnapshotTesting-Package -destination platform="iOS Simulator,name=iPhone 8,OS=11.2" | bundle exec xcpretty -r junit -o buddybuild_artifacts/SwiftTests/output-ios.xml
