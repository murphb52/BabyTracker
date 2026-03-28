# Plan: Harden Hard Delete — Per-Child Scope

## Context

The current "Hard Delete" feature has several correctness and safety problems:
- It is a global wipe of ALL children and ALL data, not scoped to a single child
- A caregiver can trigger hard delete (no role guard in the UI or AppModel)
- The CloudKit zone cleanup relies on local state only (Issue #57), leaving orphaned zones if local state is stale
- `zoneNotFound` errors during cleanup are treated as failures, not no-ops
- The user identity (name/ID) is wiped, requiring re-setup on next launch
- For children where the user is a caregiver, it tries to delete CloudKit zones owned by someone else

The user's intent: **hard delete should clean up one child's data at a time, without destroying things for other users (including other children)**.

Per-child hard delete fits cleanly with the existing architecture: each child already has its own CloudKit zone, and `purgeChildData(id:)` already exists in `SwiftDataChildRepository` to do scoped local cleanup.

---

## Problems Found

### 1. No role guard — caregiver can hard delete
`ChildProfileSettingsView.swift:69–77` shows Hard Delete unconditionally. `AppModel.hardDeleteAllData()` has no ownership check. Any active caregiver can trigger it.

### 2. Global scope — wipes all children, not just the current one
`resetAllData()` deletes ALL `StoredChild`, ALL events, ALL memberships — regardless of which child is selected. A user with two children wipes both.

### 3. User identity is wiped unnecessarily
`resetAllData()` deletes `StoredUserIdentity` and clears `localUserID` from UserDefaults. Per-child delete has no reason to wipe the user's identity.

### 4. CloudKit cleanup tries to delete zones the user doesn't own
For children where the user is a caregiver (shared zone), the current code attempts to delete the zone — owned by someone else. CloudKit rejects this with a permission error.

### 5. CloudKit cleanup is local-state-driven only (Issue #57)
If local state is stale, orphaned `child-...` zones on the server survive. If a zone was already deleted server-side, the delete call throws `zoneNotFound` and fails instead of treating it as a success.

---

## Recommended Changes

### A. Change `hardDeleteAllData()` → `hardDeleteCurrentChild()`

**File:** `AppModel.swift:107–131`

Replace the global approach with a per-child delete:
1. Guard that `profile` exists and `ChildAccessPolicy.isActiveOwner(profile.currentMembership)` — owners only
2. Capture `childID = profile.child.id`
3. Delete the child's CloudKit zone (owned children only — private scope)
4. Call the existing `childRepository.purgeChildData(id: childID)` for local cleanup
5. Clear selected child if it was this child
6. Do NOT touch user identity, other children, or their events

```swift
public func hardDeleteCurrentChild() {
    guard let profile, ChildAccessPolicy.isActiveOwner(profile.currentMembership) else { return }
    let childID = profile.child.id
    Task { @MainActor in
        var cloudDeleteError: Error?
        do {
            try await syncEngine.hardDeleteChildCloudData(childID: childID)
        } catch {
            cloudDeleteError = error
            // log
        }
        do {
            try childRepository.purgeChildData(id: childID)
            if childSelectionStore.loadSelectedChildID() == childID {
                childSelectionStore.saveSelectedChildID(nil)
            }
            clearUndoDeleteState()
            refresh(selecting: nil)
            if let cloudDeleteError { errorMessage = ... }
        } catch {
            errorMessage = resolveErrorMessage(for: error)
        }
    }
}
```

### B. Add `hardDeleteChildCloudData(childID:)` to `CloudKitSyncEngine`

**File:** `CloudKitSyncEngine.swift` + `CloudKitSyncControlling.swift`

New method scoped to a single child:
1. Try to load the local CloudKit context for this child (zone name + scope)
2. If scope is `.private` (user is owner): verify the zone exists on the server, then delete it
3. If scope is `.shared` (user is caregiver): should not be reachable (guarded at AppModel), but return early rather than attempt deletion
4. If local context is missing: still attempt to delete the expected zone (`CloudKitRecordNames.zoneID(for: childID)`) from the private database (handles stale local state — Issue #57 case)
5. Treat `CKError.zoneNotFound` as success (already gone = desired state)
6. Log clearly: deleted, already gone, or failed with reason

```swift
public func hardDeleteChildCloudData(childID: UUID) async throws {
    let zoneID: CKRecordZone.ID
    if let context = try childRepository.loadCloudKitChildContext(id: childID) {
        guard context.databaseScope == .private else { return } // caregiver — don't delete
        zoneID = context.zoneID
    } else {
        zoneID = CloudKitRecordNames.zoneID(for: childID) // fallback for stale state
    }

    do {
        try await client.modifyRecordZones(saving: [], deleting: [zoneID], databaseScope: .private)
    } catch let error as CKError where error.code == .zoneNotFound {
        // Already gone — success
        logger.info("Zone already deleted for child \(childID)")
    }
    // Other errors propagate to caller
}
```

### C. Gate hard delete to owners in the UI

**File:** `ChildProfileScreenState.swift`

Add a computed property:
```swift
public var canHardDelete: Bool {
    ChildAccessPolicy.isActiveOwner(currentMembership)
}
```

**File:** `ChildProfileSettingsView.swift:69–77`

Wrap Hard Delete `NavigationLink` behind `if profile.canHardDelete`.

### D. Update call site in `ChildWorkspaceTabView`

**File:** `ChildWorkspaceTabView.swift:82`

Change:
```swift
hardDeleteAction: { model.hardDeleteAllData() }
```
to:
```swift
hardDeleteAction: { model.hardDeleteCurrentChild() }
```

### E. Update `ChildProfileHardDeleteView` text

**File:** `ChildProfileHardDeleteView.swift`

Update description to reflect per-child scope:
- "This permanently removes **[child name]**'s profile and all logged events from this device and iCloud."
- "Other children in your account are not affected."
- Remove the "start over" framing — this is per-child cleanup, not a factory reset.

### F. Optional: Add `allZones(databaseScope:)` for fuller Issue #57 coverage

**Files:** `CloudKitClient.swift`, `LiveCloudKitClient.swift`, `UnavailableCloudKitClient.swift`

If we want to enumerate ALL server-side `child-...` zones and compare against local state (to find stale/orphaned zones), add:

```swift
func allZones(databaseScope: CKDatabase.Scope) async throws -> [CKRecordZone]
```

Implement with `CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()`.

This enables the full Issue #57 vision (enumerate from server, delete any stale `child-...` zones not found locally). This is a follow-on enhancement and can be deferred — changes A–E already address the core correctness problems and the `zoneNotFound` handling.

---

## What Does NOT Change

- `resetAllData()` is left alone (or can be removed/made private if no longer called). The user identity wipe is no longer part of hard delete.
- The `leaveChildShare()` flow for caregivers is unchanged — caregivers use "Leave Share" not "Hard Delete".
- `purgeChildData(id:)` is reused as-is — it already does the right per-child local cleanup.

---

## Files to Modify

| File | Change |
|------|--------|
| `ChildProfileScreenState.swift` | Add `canHardDelete` computed property |
| `ChildProfileSettingsView.swift` | Gate Hard Delete link behind `profile.canHardDelete` |
| `AppModel.swift` | Replace `hardDeleteAllData()` with `hardDeleteCurrentChild()` |
| `ChildWorkspaceTabView.swift` | Update call site to `hardDeleteCurrentChild()` |
| `CloudKitSyncControlling.swift` | Add `hardDeleteChildCloudData(childID:)` to protocol |
| `CloudKitSyncEngine.swift` | Implement `hardDeleteChildCloudData(childID:)` with zoneNotFound handling |
| `UnavailableCloudKitClient.swift` | Add stub if needed |
| `ChildProfileHardDeleteView.swift` | Update description text to reflect per-child scope |
| `AppModelTests.swift` | Update test mock and tests for renamed method |

---

## Issue #57 Coverage

Changes B and the `zoneNotFound` handling directly address Issue #57's core concern. Specifically:
- Fallback to `CloudKitRecordNames.zoneID(for: childID)` when local context is missing = handles stale local state
- `zoneNotFound` during cleanup = success, not error
- Scoping to `.private` only = won't attempt to delete zones the user doesn't own

Full server-side zone enumeration (the optional change F) would close Issue #57 completely — detecting ALL orphaned zones regardless of local state. This can be a separate follow-on.

---

## Verification

1. **Caregiver cannot see Hard Delete**: Log in as caregiver → navigate to Settings → Hard Delete row absent
2. **Owner can hard delete current child**: Select a child, trigger hard delete → only that child's data removed, other children intact, user identity/name preserved
3. **Multiple children**: Owner with 2 children → hard delete Child A → Child B still accessible
4. **Stale local state**: Delete child zone from CloudKit directly → run hard delete → no error, operation succeeds
5. **`zoneNotFound` is a no-op**: Simulate zone already deleted → confirm it's treated as success in logs
6. **User identity preserved**: After hard delete, app re-launches, user's display name is intact
7. **Tests pass**: `AppModelTests.swift` updated to match renamed method
