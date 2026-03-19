#!/bin/sh

set -eu

xcodebuild test \
  -project "Baby Tracker.xcodeproj" \
  -scheme "Baby Tracker" \
  -destination "platform=iOS Simulator,OS=26.2,name=iPhone 17"
