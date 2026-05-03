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

## Side-by-Side Dev Build

Debug and Release builds use different bundle identifiers so the development
build can be installed alongside the App Store build on the same device, while
both still read and write the **same** CloudKit container.

| | Debug | Release |
|---|---|---|
| Bundle ID | `com.adappt.BabyTracker.dev` | `com.adappt.BabyTracker` |
| Live Activities ext. | `com.adappt.BabyTracker.dev.LiveActivities` | `com.adappt.BabyTracker.LiveActivities` |
| Display name | `Nest Dev` | `Nest` |
| CloudKit container | `iCloud.com.adappt.BabyTracker` | `iCloud.com.adappt.BabyTracker` |
| CloudKit environment | Development | Production |
| Entitlements file | `Baby Tracker/Baby Tracker.Debug.entitlements` | `Baby Tracker/Baby Tracker.entitlements` |

The `BUNDLE_ID_SUFFIX` variable is defined in `Config/Project-Debug.xcconfig`
(`.dev`) and `Config/Project-Release.xcconfig` (empty), and is appended to the
bundle ID in `Config/App.xcconfig` and `Config/LiveActivitiesExtension.xcconfig`.

### Running the dev build

1. Open `Baby Tracker.xcodeproj` in Xcode.
2. Select the `Baby Tracker` scheme. Its Run action defaults to the **Debug**
   configuration, so a normal Cmd+R deploys the dev build.
3. The app installs as **Nest Dev** with bundle ID
   `com.adappt.BabyTracker.dev`. It can co-exist on device with the App Store
   `Nest` build.

### Verifying the dev build points at CloudKit Development

1. Run the dev build on a signed-in iCloud account and trigger a sync (add a
   child or log an event).
2. Open the [CloudKit Console](https://icloud.developer.apple.com/dashboard/),
   select container **iCloud.com.adappt.BabyTracker**, and switch to the
   **Development** environment. You should see records appear there.
3. The Production environment should remain unchanged when running the dev
   build.

The Development environment is enforced by
`com.apple.developer.icloud-container-environment = Development` in
`Baby Tracker/Baby Tracker.Debug.entitlements`. The release entitlements file
omits this key; signed App Store / TestFlight archives default to **Production**.

### Promoting CloudKit schema changes to Production

Schema changes made by the dev build live only in the Development environment
until they're explicitly deployed:

1. In the CloudKit Console, with **iCloud.com.adappt.BabyTracker** selected,
   switch to **Development**.
2. Open **Schema → Record Types** and confirm the new fields/record types are
   present and indexed correctly.
3. Click **Deploy Schema Changes…** and promote them to **Production**. This
   only deploys the schema — production data is untouched.
4. Ship the matching app update through TestFlight / the App Store so the
   production build can read/write the new schema.

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

## Xcode Cloud TestFlight Notes

The repo includes an Xcode Cloud post-build script at `ci_scripts/ci_post_xcodebuild.sh`.

It generates `TestFlight/WhatToTest.en-US.txt` during signed archive builds so TestFlight notes can include:

- the branch name
- the last three commits
- pull request title and a short summary when `CI_PULL_REQUEST_NUMBER` is available and `GITHUB_TOKEN` is configured as an Xcode Cloud secret

To enable it in Xcode Cloud, add the script to the repo and make sure the workflow runs the standard `ci_post_xcodebuild.sh` hook from the `ci_scripts` folder.
