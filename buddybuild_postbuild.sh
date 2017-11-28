#!/usr/bin/env bash

xcodebuild test -scheme SnapshotTesting-Package -destination platform="macOS"
xcodebuild test -scheme SnapshotTesting-Package -destination platform="iOS Simulator,name=iPhone 8,OS=11.2"
