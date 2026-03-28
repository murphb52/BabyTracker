# Plan: Three-Level Delete with Use Cases

## Context

The existing delete surface is a single blunt "Hard Delete" that wipes all children and all local data globally, has no role guard (caregivers can trigger it), destroys the user's own identity, and makes incorrect CloudKit calls for zones owned by other users.

The goal is to replace this with three clearly-scoped, role-aware operations — each backed by a dedicated `UseCase` — that clean up data without damaging other users.

---

## Current State (already landed)

Several changes were already made and are in place:
- `ChildProfileScreenState.canHardDelete` computed property (owner-only guard)
- `ChildProfileSettingsView` gates Hard Delete UI behind `canHardDelete`, passes `childName`
- `ChildProfileHardDeleteView` updated with `childName` and per-child description text
- `CloudKitSyncControlling.hardDeleteChildCloudData(childID:)` in protocol
- `CloudKitSyncEngine.hardDeleteChildCloudData(childID:)` implemented with `zoneNotFound` as success and stale-state fallback
- `AppModel.hardDeleteCurrentChild()` calling the above (owner-only, no formal UseCase yet)

---

## Three Levels

### Level 1 — Archive (owner-only soft delete)
**What it does:**
- Sets `isArchived = true` on the child
- Revokes all active caregiver memberships (status → `.removed`)
- Fires `removeParticipant()` on CloudKit for each revoked caregiver
- Clears child selection if needed
- Child data is preserved; owner can restore later (caregivers would need to be re-invited)

**Who can trigger it:** Active owners only (`ChildAccessPolicy.canPerform(.archiveChild, ...)`)

### Level 2 — Hard Delete Child (role-aware, per-child)
**Owner path:**
1. Remove all CloudKit share participants (so caregivers cleanly lose access before zone deletion)
2. Delete the child's CloudKit zone (`hardDeleteChildCloudData`)
3. Purge all local data for the child (`purgeChildData`)

**Caregiver path:**
1. Leave the CloudKit share zone (`leaveShare`)
2. Purge local data for that child (`purgeChildData`)

**Who can trigger it:** Any active member (owner or caregiver). Role determines which CloudKit path is taken.

**UI note:** The current Hard Delete button in settings is owner-only (`canHardDelete`). Caregiver equivalent ("Leave Child" or similar) can live in the Sharing view where `canLeaveShare` is already used — or a unified option can be added gated per-role. Scope of this plan: the UseCase and AppModel wiring; UI unification is a follow-on.

### Level 3 — Nuke Everything (account-level reset)
**What it does:**
1. Loads all children the local user has any membership for
2. For each child where user is a **caregiver**: leaves the CloudKit share
3. For each child where user is an **owner**: deletes the CloudKit zone (via `hardDeleteChildCloudData`)
4. Wipes ALL local data including user identity (`userIdentityRepository.resetAllData()`)
5. Clears selection, undo state

**Who can trigger it:** Any authenticated local user (it only touches their own data)

**UI note:** Requires a new screen with heavy explanation and a two-step confirmation. This is account-level so it needs an entry point outside of per-child settings — likely a new "Account Settings" or "My Account" section accessible from the child list screen.

---

## Use Cases to Create / Modify

### 1. Update `ArchiveCurrentChildUseCase` → `ArchiveChildUseCase`

**File:** `Packages/BabyTrackerDomain/Sources/BabyTrackerDomain/UseCases/ArchiveCurrentChildUseCase.swift`

**Changes:**
- Rename struct to `ArchiveChildUseCase`
- Add `membershipRepository: any MembershipRepository` as a constructor dependency
- After setting `isArchived = true`, load all memberships for the child, call `membership.removed()` on each active caregiver membership, save each to `membershipRepository`
- Change `Output` from `Void` to `[Membership]` (the revoked caregiver memberships)
- AppModel's `archiveCurrentChild()` uses the returned memberships to fire async `syncEngine.removeParticipant()` for each

**Updated signature:**
```swift
public func execute(_ input: Input) throws -> [Membership]
// Returns revoked caregiver memberships for caller to clean up in CloudKit
```

### 2. New `HardDeleteChildUseCase`

**File:** `Packages/BabyTrackerDomain/Sources/BabyTrackerDomain/UseCases/HardDeleteChildUseCase.swift`

**Purpose:** Validates permissions and declares intent. No side effects — the caller (AppModel) performs the async CloudKit and sync local purge in the correct order (CloudKit first, local purge after).

```swift
public enum HardDeleteChildIntent: Sendable {
    case deleteOwnedZone    // owner: caller deletes zone, then purges local
    case leaveCaregiverShare // caregiver: caller leaves share, then purges local
}

@MainActor
public struct HardDeleteChildUseCase: UseCase {
    public struct Input {
        public let membership: Membership
    }
    public typealias Output = HardDeleteChildIntent

    public func execute(_ input: Input) throws -> HardDeleteChildIntent {
        guard input.membership.status == .active else {
            throw ChildProfileValidationError.insufficientPermissions
        }
        return input.membership.role == .owner ? .deleteOwnedZone : .leaveCaregiverShare
    }
}
```

No repository dependencies needed — pure policy logic.

### 3. New `NukeAllDataUseCase`

**File:** `Packages/BabyTrackerDomain/Sources/BabyTrackerDomain/UseCases/NukeAllDataUseCase.swift`

**Purpose:** Loads all children the user has memberships for and classifies them by role. Returns the CloudKit operations that need to fire. Does not mutate local state — that happens in AppModel after CloudKit cleanup (local context must be available for CloudKit zone IDs).

```swift
public struct NukeAllDataIntent: Sendable {
    public let ownedChildIDs: [UUID]     // → caller fires hardDeleteChildCloudData for each
    public let caregiverChildIDs: [UUID] // → caller fires leaveShare for each
}

@MainActor
public struct NukeAllDataUseCase: UseCase {
    public struct Input {
        public let localUserID: UUID
    }
    public typealias Output = NukeAllDataIntent

    private let childRepository: any ChildRepository
    private let membershipRepository: any MembershipRepository

    public func execute(_ input: Input) throws -> NukeAllDataIntent {
        let allChildren = try childRepository.loadAllChildren()
        var ownedIDs: [UUID] = []
        var caregiverIDs: [UUID] = []
        for child in allChildren {
            let memberships = try membershipRepository.loadMemberships(for: child.id)
            guard let mine = memberships.first(where: { $0.userID == input.localUserID && $0.status == .active }) else { continue }
            if mine.role == .owner { ownedIDs.append(child.id) }
            else { caregiverIDs.append(child.id) }
        }
        return NukeAllDataIntent(ownedChildIDs: ownedIDs, caregiverChildIDs: caregiverIDs)
    }
}
```

AppModel's `nukeAllData()` then:
1. Calls the use case → gets `NukeAllDataIntent`
2. Fires `syncEngine.leaveShare(childID:)` for each caregiver child
3. Fires `syncEngine.hardDeleteChildCloudData(childID:)` for each owned child
4. Calls `userIdentityRepository.resetAllData()` — wipes all local data including user identity
5. Clears selection, undo state, refreshes

---

## AppModel Changes

**File:** `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/AppModel.swift`

### `archiveCurrentChild()`
Update to use renamed `ArchiveChildUseCase` and handle the `[Membership]` return:
```swift
public func archiveCurrentChild() {
    perform {
        guard let profile else { return }
        let revokedCaregivers = try ArchiveChildUseCase(
            childRepository: childRepository,
            membershipRepository: membershipRepository,
            childSelectionStore: childSelectionStore
        ).execute(.init(
            child: profile.child,
            membership: profile.currentMembership,
            currentSelectedChildID: childSelectionStore.loadSelectedChildID()
        ))
        // Fire async CloudKit participant removal for each revoked caregiver
        for membership in revokedCaregivers {
            Task { @MainActor in
                try? await syncEngine.removeParticipant(membership: membership)
            }
        }
    }
}
```

### `hardDeleteCurrentChild()`
Update to use `HardDeleteChildUseCase` for role determination, and support the caregiver path:
```swift
public func hardDeleteCurrentChild() {
    guard let profile else { return }
    let intent = try? HardDeleteChildUseCase().execute(.init(membership: profile.currentMembership))
    guard let intent else { return }
    let childID = profile.child.id
    Task { @MainActor in
        var cloudError: Error?
        do {
            switch intent {
            case .deleteOwnedZone:
                try await syncEngine.hardDeleteChildCloudData(childID: childID)
            case .leaveCaregiverShare:
                try await syncEngine.leaveShare(childID: childID)
            }
        } catch { cloudError = error }
        do {
            try childRepository.purgeChildData(id: childID)
            if childSelectionStore.loadSelectedChildID() == childID {
                childSelectionStore.saveSelectedChildID(nil)
            }
            clearUndoDeleteState()
            refresh(selecting: nil)
            if let cloudError { errorMessage = "Local data cleared, but iCloud cleanup failed: \(cloudError.localizedDescription)" }
        } catch {
            errorMessage = resolveErrorMessage(for: error)
        }
    }
}
```

### New `nukeAllData()`
```swift
public func nukeAllData() {
    guard let localUser else { return }
    Task { @MainActor in
        let intent: NukeAllDataIntent
        do {
            intent = try NukeAllDataUseCase(
                childRepository: childRepository,
                membershipRepository: membershipRepository
            ).execute(.init(localUserID: localUser.id))
        } catch {
            errorMessage = resolveErrorMessage(for: error)
            return
        }

        // CloudKit cleanup (best effort — errors logged but don't block local wipe)
        for childID in intent.caregiverChildIDs {
            try? await syncEngine.leaveShare(childID: childID)
        }
        for childID in intent.ownedChildIDs {
            try? await syncEngine.hardDeleteChildCloudData(childID: childID)
        }

        // Full local reset including user identity
        do {
            try userIdentityRepository.resetAllData()
            childSelectionStore.saveSelectedChildID(nil)
            clearUndoDeleteState()
            refresh(selecting: nil)
        } catch {
            errorMessage = resolveErrorMessage(for: error)
        }
    }
}
```

---

## UI Changes

### Archive (existing, minor update)
`ChildProfileSettingsView` already shows Archive for `profile.canArchiveChild` (owner-only). No UI change needed — the use case update handles the caregiver revocation automatically.

### Hard Delete Child (existing, already done)
`ChildProfileHardDeleteView` with `childName` already done. The button currently routes to `model.hardDeleteCurrentChild()`. Once AppModel is updated to use the use case and support the caregiver path, UI is already correct for owners. Caregiver entry-point (e.g. from Sharing view) can be wired to the same `hardDeleteCurrentChild()` — it'll take the leave-share path automatically.

### Nuke Everything (new)

**New file:** `Packages/BabyTrackerFeature/Sources/BabyTrackerFeature/Views/NukeAllDataView.swift`

- List with two explanation sections:
  - Section 1: What will be deleted (all owned children and their data, all caregiver shares removed, your account identity removed)
  - Section 2: What won't be deleted (other users' data is unaffected)
- Button: "Erase Everything" (destructive)
- First confirmation alert: "Are you sure?"
- Second confirmation: require user to type "DELETE" or similar to confirm (optional — at minimum, two-tap confirmation)
- Calls `model.nukeAllData()`

**Entry point:** Add "Account" or "Danger Zone" section to the child list / no-child state screen (or top-level app settings). The specific placement depends on existing navigation structure — scope of this plan is the view and AppModel wiring only.

---

## Files to Create / Modify

| File | Change |
|------|--------|
| `UseCases/ArchiveCurrentChildUseCase.swift` | Rename to `ArchiveChildUseCase`, add caregiver revocation, change output to `[Membership]`, add `membershipRepository` dependency |
| `UseCases/HardDeleteChildUseCase.swift` | **New** — pure policy use case, returns `HardDeleteChildIntent` |
| `UseCases/NukeAllDataUseCase.swift` | **New** — classifies all children by role, returns `NukeAllDataIntent` |
| `AppModel.swift` | Update `archiveCurrentChild()`, update `hardDeleteCurrentChild()` to use use case + caregiver path, add `nukeAllData()` |
| `Views/NukeAllDataView.swift` | **New** — heavily confirmed nuke screen |
| `AppModelTests.swift` | Add tests for all three operations |

**No new CloudKit protocol methods needed** — `hardDeleteChildCloudData` and `leaveShare` are sufficient for all three levels.

---

## Issue #57 Coverage

Already addressed by the existing `hardDeleteChildCloudData` implementation:
- Stale-state fallback: falls back to canonical zone name when local context is missing
- `zoneNotFound` treated as success
- Only deletes owned (private) zones — never attempts to delete shared zones

---

## Verification

1. **Archive removes caregivers**: Archive a child with active caregivers → caregivers' local view of that child disappears on next sync, CloudKit share participant removed
2. **Archive is owner-only**: Log in as caregiver → Settings → "Archive Child" row absent
3. **Hard Delete Child (owner)**: Select owned child → Hard Delete → only that child gone, user identity and other children intact
4. **Hard Delete Child (caregiver, via leave share)**: Wire caregiver path → child removed locally, owner's data untouched
5. **Nuke (owned + caregiver mix)**: User owns Child A, is caregiver for Child B → Nuke → both removed locally, Child B still exists under its owner, user identity wiped, app shows onboarding on relaunch
6. **Nuke with stale state**: Manually delete a zone on server before nuking → nuke completes without error
7. **Tests**: All three use cases covered with unit tests using in-memory repositories
