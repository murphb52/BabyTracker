# Simple Baby Tracker - Technical Design Specification

## 1. Overview

Local-first iOS app for fast baby event tracking with shared caregiver
sync via CloudKit.

## 2. Technology Stack

-   Swift, SwiftUI
-   SwiftData
-   CloudKit
-   ActivityKit
-   Git
-   Xcode xcconfig files for checked-in build settings

## 3. Architecture

Presentation / Domain / Data / App Composition layers.

## 4. Packages

### Stage 0 packages created now

-   BabyTrackerDomain
-   BabyTrackerPersistence
-   BabyTrackerSync
-   BabyTrackerFeature

### Deferred until first use

-   BabyTrackerDesignSystem
-   BabyTrackerLiveActivities
-   BabyTrackerTestSupport

## 5. Data Model (Strongly Typed)

### Event Metadata

Shared across all event types.

``` swift
struct EventMetadata {
    let id: UUID
    let childID: UUID
    let occurredAt: Date
    let createdAt: Date
    let createdBy: String
    let updatedAt: Date
    let updatedBy: String
    let notes: String
    let isDeleted: Bool
    let deletedAt: Date?
}
```

### Event Types

``` swift
struct BreastFeedEvent {
    let metadata: EventMetadata
    let side: BreastSide
    let startedAt: Date
    let endedAt: Date
}
```

``` swift
struct BottleFeedEvent {
    let metadata: EventMetadata
    let amountML: Int
    let milkType: MilkType?
}
```

``` swift
struct SleepEvent {
    let metadata: EventMetadata
    let startedAt: Date
    let endedAt: Date?
}
```

``` swift
struct NappyEvent {
    let metadata: EventMetadata
    let type: NappyType
    let intensity: NappyIntensity?
    let pooColor: PooColor?
}
```

`pooColor` is only valid when `type` is `.poo` or `.mixed`.

### Event Wrapper

``` swift
enum Event {
    case breastFeed(BreastFeedEvent)
    case bottleFeed(BottleFeedEvent)
    case sleep(SleepEvent)
    case nappy(NappyEvent)
}
```

### Key Principles

-   No unnecessary optionals
-   Duration is derived, not stored
-   `milkType` is optional for bottle feeds in the MVP
-   Nappy validation prevents invalid field combinations
-   Strong typing enforces valid data combinations

### Stage 0 shared identity models

``` swift
struct Child {
    let id: UUID
    let name: String
    let birthDate: Date?
    let createdAt: Date
    let createdBy: UUID
    let isArchived: Bool
}
```

``` swift
struct UserIdentity {
    let id: UUID
    let displayName: String
    let createdAt: Date
}
```

``` swift
enum MembershipRole {
    case owner
    case caregiver
}
```

``` swift
enum MembershipStatus {
    case invited
    case active
    case removed
}
```

``` swift
struct Membership {
    let id: UUID
    let childID: UUID
    let userID: UUID
    let role: MembershipRole
    let status: MembershipStatus
    let invitedAt: Date
    let acceptedAt: Date?
}
```

## 6. Persistence

Local-first writes via repository pattern with separate models per event
type.

## 7. Sync

CloudKit with last-write-wins and offline support.

## 8. Derived Data

Computed from typed events.

## 9. Features

Logging, timeline, edit/delete, sleep tracking.

## 10. Live Activities

Feed timer and last event display.

## 11. Testing

Unit + integration tests.

## 12. Git Workflow

Atomic commits, feature branches.

## 13. Pre-Commit Hook

Run tests before commit.

## 14. External Setup

### Apple Developer

-   Create App ID `com.adappt.BabyTracker`
-   Create iCloud container `iCloud.com.adappt.BabyTracker`
-   Enable iCloud and CloudKit
-   Leave Live Activities capability for the later Live Activities stage

### Xcode

-   Configure signing
-   Enable capabilities
-   Select a local development team before generic device builds

### CloudKit

-   Create container
-   Define schema (Child, Event types, Membership) in Stage 2
-   Test sharing after Stage 1 and Stage 2 are in place
-   Promote to production after schema stabilises

### Testing Accounts

-   Two iCloud users
-   Real device testing

### App Store Connect

-   Create app
-   Setup TestFlight

### Git

-   Protect main branch
-   Require PRs

### CI

-   Run tests on PRs

### Hooks

-   No repository-managed Git hooks in Stage 0

## 15. Principles

-   Local-first
-   Strong typing over flexibility
-   Derived state
-   Fast UX
