# Baby Tracker

An iOS app for tracking your baby's activities, built with SwiftUI and clean architecture principles.

## Features

- Track feeding, sleep, nappy changes, and other activities
- Support for multiple children
- CloudKit-backed sync across devices
- Live Activities support

## Architecture

The project is organized around clean architecture using Swift Packages as architectural boundaries:

- **Domain** — business rules, entities, use cases, and protocols
- **Data** — repository implementations, CloudKit/SwiftData persistence, and DTO mapping
- **Presentation** — SwiftUI views, view models, and UI state

See [Claude.md](Claude.md) for detailed engineering guidelines.

## Requirements

- iOS 18+
- Xcode 16+

## Getting Started

1. Clone the repository
2. Open `Baby Tracker.xcodeproj` in Xcode
3. Select a simulator or device and run

## Running Tests

```sh
xcodebuild test \
  -project "Baby Tracker.xcodeproj" \
  -scheme "Baby Tracker" \
  -parallel-testing-enabled NO \
  -destination "platform=iOS Simulator,OS=26.2,name=iPhone 17"
```

## CI

| Workflow | Trigger |
|----------|---------|
| Build | PRs and pushes to `main` |
| Build and Test | PRs and pushes to `main` |
