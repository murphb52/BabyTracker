#!/bin/bash

# Get the booted simulator
SIMULATOR_UDID=$(xcrun simctl list devices | grep "iPhone 17" | grep "Booted" | grep -oE '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}' | head -1)

if [ -z "$SIMULATOR_UDID" ]; then
  echo "❌ No booted iPhone 17 simulator found"
  exit 1
fi

echo "📱 Sending notifications to iPhone 17 simulator ($SIMULATOR_UDID)..."
echo ""

for file in docs/testing/*.apns; do
  filename=$(basename "$file")
  xcrun simctl push "$SIMULATOR_UDID" "$file" && echo "✅ $filename" || echo "❌ $filename"
done

echo ""
echo "Done!"
