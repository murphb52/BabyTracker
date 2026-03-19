# Simple Baby Tracker - PRD

**Platform:** Native iOS (Swift / SwiftUI)\
**Version:** 1.1 (MVP - Refined)\
**Date:** March 2026

------------------------------------------------------------------------

## 1. Overview

The Simple Baby Tracker is a lightweight iOS application designed to
help parents track a baby's daily activities quickly and reliably.

The product prioritises speed, clarity, and shared visibility between
caregivers, especially in low-attention, high-fatigue situations.

------------------------------------------------------------------------

## 2. Product Principles

-   Fast \> Feature-rich\
-   Reliable \> Clever\
-   Usable at 3am with one hand\
-   Shared truth between caregivers\
-   Local-first, sync-safe\
-   Build in layers: useful -\> complete -\> insightful

------------------------------------------------------------------------

## 3. Goals

### Primary

-   Log events in ≤ 5 seconds (p95, from app open to local save)\
-   Provide a clear, immediate understanding of baby's current state\
-   Ensure consistent shared data across caregivers

### Secondary

-   Enable pattern recognition over time\
-   Reduce cognitive load during logging and review

------------------------------------------------------------------------

## 4. Platform & Technology

-   Native iOS app\
-   iPhone + iPad only for the MVP\
-   Swift + SwiftUI\
-   Local persistence (SwiftData)\
-   iCloud (CloudKit) for sync and backup\
-   Live Activities support

------------------------------------------------------------------------

## 5. Core Features

### Feeding Tracking

-   Breast feed (duration in minutes)\
-   Bottle feed (amount in ml)

### Nappy Tracking

-   Types: Dry, Wee, Poo, Mixed\
-   Optional attributes:
    -   Intensity (Low / Medium / High)\
    -   Colour (Yellow, Mustard, Brown, Green, Black, Other)
-   `pooColor` is only valid for Poo and Mixed nappies\
-   Poo consistency is out of scope for the MVP

### Sleep Tracking

-   Start time\
-   End time\
-   Automatic duration calculation

### Event Management

-   Create, edit, delete events\
-   Immediate undo after delete

### Timeline

-   Time-based day view showing events in chronological order\
-   Designed for rapid scanning, recency awareness, and gap detection\
-   Supports overlapping events

### Live Activity

-   Last feed time\
-   Time since last feed\
-   Feed type

### Summary

-   Daily totals (feeds, sleep, nappies)\
-   Trends (future stage: intervals, averages, patterns)

------------------------------------------------------------------------

## 6. Data Model

The system is structured around a shared child profile and a timestamped
event log.

### Child Profile

Represents the baby being tracked.

Fields: - childId\
- name\
- birthDate (optional)\
- createdAt\
- createdBy\
- isArchived

Typed definition:

```swift
struct Child {
    let childId: UUID
    let name: String
    let birthDate: Date?
    let createdAt: Date
    let createdBy: UUID
    let isArchived: Bool
}
```

------------------------------------------------------------------------

### User

Represents a caregiver identity.

Fields: - userId\
- displayName\
- createdAt

Typed definition:

```swift
struct UserIdentity {
    let userId: UUID
    let displayName: String
    let createdAt: Date
}
```

------------------------------------------------------------------------

### Membership

Represents access to a child profile.

Fields: - membershipId\
- childId\
- userId\
- role (owner, caregiver)\
- status (invited, active, removed)\
- invitedAt\
- acceptedAt

Typed definition:

```swift
struct Membership {
    let membershipId: UUID
    let childId: UUID
    let userId: UUID
    let role: MembershipRole
    let status: MembershipStatus
    let invitedAt: Date
    let acceptedAt: Date?
}
```

------------------------------------------------------------------------

### Event (Base Object)

All tracked activities are stored as events.

Fields: - eventId\
- childId\
- type (feedBreast, feedBottle, nappy, sleep)\
- startAt\
- endAt (optional)\
- notes (optional)\
- createdAt / createdBy\
- updatedAt / updatedBy\
- isDeleted\
- deletedAt (optional)

------------------------------------------------------------------------

### Event Details (Per Type)

**Breast Feed** - durationMinutes\
- side (optional: left, right, both)

**Bottle Feed** - amountMl\
- milkType (optional)

**Nappy** - nappyType\
- intensity (optional)\
- pooColor (optional)
- `pooColor` only when `nappyType` is `poo` or `mixed`

**Sleep** - startAt\
- endAt\
- durationMinutes (derived)

------------------------------------------------------------------------

### Derived Data (Not Stored as Source of Truth)

Computed from events: - Time since last feed\
- Total feeds today\
- Total sleep today\
- Last nappy time\
- Active sleep session\
- Daily summaries

------------------------------------------------------------------------

## 7. Sync & Shared Data

### Architecture

-   Local-first persistence on device\
-   CloudKit used for syncing shared data\
-   Shared record zone per child profile

### Model

-   Each event has a stable ID\
-   All changes update `updatedAt` and `updatedBy`\
-   Sync is asynchronous and automatic

### Conflict Resolution

-   Event-level last-write-wins\
-   The most recent successful write becomes the source of truth\
-   No field-level merging in MVP\
-   Deletes are soft deletes and participate in conflict resolution

### Offline Behaviour

-   Events are saved locally immediately\
-   Sync occurs when connectivity is available\
-   System guarantees eventual consistency across devices

------------------------------------------------------------------------

## 8. Permissions & Identity

### Identity

-   Based on user's Apple account (via iCloud)

------------------------------------------------------------------------

### Roles

**Owner** - Creates child profile\
- Invites/removes caregivers\
- Manages profile settings

**Caregiver** - Can view all data\
- Can create, edit, and delete events

------------------------------------------------------------------------

### Access Model

-   One owner per child profile\
-   One or more caregivers (MVP supports at least one)\
-   All caregivers share equal access to event data

------------------------------------------------------------------------

### Behaviour Rules

-   Caregivers can edit and delete any event\
-   Deletion supports undo\
-   Ownership transfer is out of scope for MVP\
-   Removed caregivers lose access to shared data

------------------------------------------------------------------------

### Membership Lifecycle

-   Invited → Active → Removed

------------------------------------------------------------------------

## 9. UX Requirements

-   One-handed usage\
-   Minimal input required for common actions\
-   Default values reduce friction (e.g. current time)\
-   Fast correction (edit/delete/undo)\
-   Clear empty states\
-   Non-blocking error handling\
-   Optimised for low-attention use

------------------------------------------------------------------------

## 10. Error States & Recovery

### Principles

-   Never lose user data silently\
-   Prioritise local save over remote sync\
-   Avoid blocking core flows\
-   Use simple, clear messaging

------------------------------------------------------------------------

### Key Scenarios

**Offline Logging** - Events saved locally\
- Marked as pending sync\
- Sync resumes automatically

------------------------------------------------------------------------

**Sync Delays / Failures** - Local data remains accessible\
- Automatic retry with backoff\
- Persistent failures surfaced to user

------------------------------------------------------------------------

**Conflict Resolution** - Last-write-wins applied automatically\
- No manual merge required in MVP

------------------------------------------------------------------------

**Invalid Input** - Prevent invalid entries where possible\
- Use inline validation

------------------------------------------------------------------------

**Deletion** - Soft delete with immediate undo\
- Recovery available within session window

------------------------------------------------------------------------

**Account / iCloud Issues** - Inform user when sync unavailable\
- Allow continued local usage where possible

------------------------------------------------------------------------

## 11. Staged Delivery

### Stage 1

-   Child profile\
-   Identity + sharing

### Stage 2

-   Local data model\
-   CloudKit sync

### Stage 3

-   Feeding tracking\
-   Quick logging

### Stage 4

-   Event editing\
-   Undo\
-   Empty states

### Stage 5

-   Last event summary\
-   Live Activity

### Stage 6

-   Nappy tracking

### Stage 7

-   Sleep tracking

### Stage 8

-   Timeline view

### Stage 9

-   Speed improvements (timers, widgets)

### Stage 10

-   Insights and trends

------------------------------------------------------------------------

## 12. Success Metrics

-   Event logging time ≤ 5 seconds (p95)\
-   Daily active usage rate (target to be defined)\
-   Sync success rate ≥ 99%\
-   Zero data loss incidents

------------------------------------------------------------------------

## 13. Risks

-   Sync conflicts and edge cases\
-   Shared access complexity\
-   Over-engineering before core usage is validated

------------------------------------------------------------------------

## 14. Future Considerations

-   Multi-child support\
-   Notifications and reminders\
-   Health integrations\
-   Cross-platform support

------------------------------------------------------------------------

## Summary

Start with fast, reliable event logging and shared visibility.\
Build a trustworthy event log first, then layer insight and intelligence
on top.
