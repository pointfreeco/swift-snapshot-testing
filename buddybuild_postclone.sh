#!/usr/bin/env bash

system_profiler SPSoftwareDataType
xcodebuild -showsdks
swift package generate-xcodeproj
