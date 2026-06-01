# 110 — Medication Reminder Notifications

GitHub issue: https://github.com/murphb52/BabyTracker/issues/267

## Goal

Allow caregivers to opt in to a local notification when logging a medication event. The notification fires after a chosen interval and reminds the caregiver either that it is safe to give the next dose, or that the next dose is due. The app remembers the last used interval, mode, and reference point per medicine per child, and suggests them the next time the same medicine is logged.

---

## Design decisions

### Two notification modes

The user picks their framing when logging:

- **Safe to give**: "Calpol – Safe to give again" / "It's been 4 hours since {childName}'s last dose."
- **Next dose due**: "Calpol – Next dose due" / "{childName}'s next Calpol dose is due now."

### Reference point

The user chooses whether the interval is measured from:

- **Dose time** (`occurredAt`) — medically precise
- **Now** — useful when logging in real time

The calculated fire time is shown inline in the sheet ("Your reminder will fire at 10:00 PM") so the user can verify before saving.

### Interval picker

- Quick chips: 2h, 4h, 6h, 8h
- Custom stepper: 1–24 hours
- Hours granularity only for v1

### Preference storage

`MedicationReminderPreference` — a `Codable` struct stored in `UserDefaults` keyed by `"medicationReminder.\(childID).\(medicineName)"`.

Fields:
- `intervalHours: Int`
- `mode: ReminderMode` (`.safeToGive` | `.nextDueDose`)
- `referencePoint: ReminderReferencePoint` (`.doseTime` | `.now`)

When the reminder toggle is turned on and a saved preference exists for this medicine+child, all three values pre-fill.

### Notification identifier

`"medication.\(childID.uuidString).\(medicineName)"` — one active reminder per medicine+child at a time.

### Replacement and cancellation

- **New dose logged with reminder on**: cancel existing identifier, schedule new one.
- **New dose logged with reminder off**: cancel existing identifier, do not schedule.
- **Event deleted**: cancel existing identifier.
- **Event edited**: no change to reminder for v1.

### Timeline indicator

The medication event card in the timeline shows a pending reminder chip ("Reminder: 10:00 PM ✕"). Tapping ✕ cancels the notification. This uses the same `pendingNotifications()` query pattern as drift notifications.

### Architecture

- `MedicationReminderPreference` — domain-layer value type (`Codable` struct)
- `MedicationReminderPreferenceStore` — protocol in Feature layer (read/write by medicine+child key)
- `UserDefaultsMedicationReminderPreferenceStore` — concrete implementation in the App target
- `ScheduleMedicationReminderUseCase` — Feature layer; computes fire date, builds notification content, saves preference, calls `LocalNotificationManaging`
- `CancelMedicationReminderUseCase` — Feature layer; cancels by identifier
- `LocalNotificationManaging` — extend with `scheduleMedicationReminderNotification(...)` and `cancelMedicationReminderNotification(childID:medicineName:)`
- `NoOpLocalNotificationManager` — add no-op implementations
- View model for `MedicationEditorSheetView` — calls log use case, then on success calls schedule or cancel use case; reads saved preference to pre-fill UI

---

## Implementation steps

### 1. Domain — `MedicationReminderPreference`

- [ ] Add `MedicationReminderPreference.swift` to `BabyTrackerDomain`
  - `ReminderMode` enum: `.safeToGive`, `.nextDueDose`
  - `ReminderReferencePoint` enum: `.doseTime`, `.now`
  - `MedicationReminderPreference` struct: `intervalHours: Int`, `mode: ReminderMode`, `referencePoint: ReminderReferencePoint`
  - All types `Codable`, `Equatable`, `Sendable`

### 2. Feature — preference store protocol and implementation

- [ ] Add `MedicationReminderPreferenceStore.swift` to `BabyTrackerFeature`
  - Protocol: `func preference(for medicineName: String, childID: UUID) -> MedicationReminderPreference?`
  - Protocol: `func savePreference(_ preference: MedicationReminderPreference, for medicineName: String, childID: UUID)`
- [ ] Add `UserDefaultsMedicationReminderPreferenceStore.swift` to the App target
  - Key: `"medicationReminder.\(childID.uuidString).\(medicineName)"`
  - Encode/decode with `JSONEncoder`/`JSONDecoder`
- [ ] Add `NoOpMedicationReminderPreferenceStore` for tests/previews

### 3. Feature — extend `LocalNotificationManaging`

- [ ] Add to `LocalNotificationManaging` protocol:
  - `scheduleMedicationReminderNotification(childID: UUID, childName: String, medicineName: String, mode: ReminderMode, fireAt: Date) async`
  - `cancelMedicationReminderNotification(childID: UUID, medicineName: String) async`
- [ ] Implement in `SystemLocalNotificationManager`:
  - Identifier: `"medication.\(childID.uuidString).\(medicineName)"`
  - Safe mode title: `"\(medicineName) – Safe to give again"`
  - Safe mode body: `"It's been \(intervalHours)h since \(childName)'s last dose."`
  - Due mode title: `"\(medicineName) – Next dose due"`
  - Due mode body: `"\(childName)'s next \(medicineName) dose is due now."`
  - Trigger: `UNCalendarNotificationTrigger` from fire date (not time-interval, so it survives device restart)
  - Cancel existing identifier before scheduling
- [ ] Add no-op stubs to `NoOpLocalNotificationManager`

### 4. Feature — `ScheduleMedicationReminderUseCase`

- [ ] Add `ScheduleMedicationReminderUseCase.swift` to `BabyTrackerFeature`
  - Input: `childID`, `childName`, `medicineName`, `preference: MedicationReminderPreference`, `occurredAt: Date`, `now: Date`
  - Computes `fireAt`: `referencePoint == .doseTime ? occurredAt + interval : now + interval`
  - Guards: if `fireAt <= now`, return without scheduling
  - Saves preference via `MedicationReminderPreferenceStore`
  - Calls `localNotificationManager.scheduleMedicationReminderNotification(...)`

### 5. Feature — `CancelMedicationReminderUseCase`

- [ ] Add `CancelMedicationReminderUseCase.swift` to `BabyTrackerFeature`
  - Input: `childID`, `medicineName`
  - Calls `localNotificationManager.cancelMedicationReminderNotification(childID:medicineName:)`

### 6. Feature — extend `pendingNotifications` query

- [ ] Add `pendingMedicationReminderNotifications() async -> [PendingMedicationReminder]` to `LocalNotificationManaging`
  - `PendingMedicationReminder`: `id: String`, `childID: UUID`, `medicineName: String`, `fireDate: Date`
  - Filter pending requests with prefix `"medication."`
  - Implement in `SystemLocalNotificationManager` and `NoOpLocalNotificationManager`

### 7. Presentation — `MedicationEditorSheetView` reminder section

- [ ] Extend the medication editor view model to expose:
  - `savedPreference: MedicationReminderPreference?` (loaded on init for current medicine+child)
  - `isReminderEnabled: Bool`
  - `selectedIntervalHours: Int`
  - `reminderMode: ReminderMode`
  - `referencePoint: ReminderReferencePoint`
  - `calculatedFireDate: Date?` (derived, for display)
- [ ] Add reminder section to `MedicationEditorSheetView`:
  - Toggle: "Set a reminder"
  - When on: quick chips (2h, 4h, 6h, 8h), custom stepper (1–24h)
  - Mode picker: "Safe to give" / "Next dose due"
  - Reference point picker: "From dose time" / "From now"
  - Calculated fire time label: "Your reminder will fire at 10:00 PM"
  - Pre-fill all fields from `savedPreference` when toggled on if preference exists
- [ ] After successful log: call `ScheduleMedicationReminderUseCase` if reminder enabled, else call `CancelMedicationReminderUseCase`
- [ ] Add `#Preview` states: reminder off, reminder on with saved preference, reminder on with no preference, fire date in past (disabled state)

### 8. Presentation — delete flow cancels reminder

- [ ] After a medication event is deleted, call `CancelMedicationReminderUseCase` for that event's `childID` and `medicineName`
- [ ] Find the delete path for medication events and wire in the cancel call

### 9. Presentation — timeline card indicator

- [ ] Extend the medication event card to query `pendingMedicationReminderNotifications()` and show a chip if a reminder exists for this event's `childID` + `medicineName`
- [ ] Chip format: "Reminder: 10:00 PM ✕"
- [ ] Tapping ✕ calls `CancelMedicationReminderUseCase` and refreshes the card

### 10. Dependency injection

- [ ] Add `MedicationReminderPreferenceStore` and `ScheduleMedicationReminderUseCase` / `CancelMedicationReminderUseCase` to `AppContainer`
- [ ] Inject into the medication editor view model

### 11. Notification permission

- [ ] When the reminder toggle is turned on and notification permission has not been granted, call `requestAuthorizationIfNeeded()` before showing the reminder options
- [ ] If permission is denied, show a brief inline message and leave the toggle off

### 12. Tests

- [ ] `MedicationReminderPreference` encode/decode round-trip
- [ ] `ScheduleMedicationReminderUseCase`: fire date calculated correctly for both reference points
- [ ] `ScheduleMedicationReminderUseCase`: skips scheduling when fire date is in the past
- [ ] `ScheduleMedicationReminderUseCase`: saves preference to store
- [ ] `CancelMedicationReminderUseCase`: calls cancel on notification manager
- [ ] `UserDefaultsMedicationReminderPreferenceStore`: read/write/overwrite

---

## Out of scope for v1

- Deep-link from notification tap into the child's timeline
- Edit event shifts the reminder
- Cross-caregiver CloudKit sync of reminder preferences
- Minutes granularity in interval picker
- Rich notification actions ("Mark as given" from lock screen)

---

- [x] Complete
