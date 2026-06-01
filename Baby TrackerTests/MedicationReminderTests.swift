import BabyTrackerDomain
import BabyTrackerFeature
import Foundation
import Testing

struct MedicationReminderPreferenceTests {
    @Test
    func encodesAndDecodesRoundTrip() throws {
        let preference = MedicationReminderPreference(
            intervalHours: 4,
            mode: .safeToGive,
            referencePoint: .doseTime
        )
        let data = try JSONEncoder().encode(preference)
        let decoded = try JSONDecoder().decode(MedicationReminderPreference.self, from: data)
        #expect(decoded == preference)
    }

    @Test
    func encodesAndDecodesAllModes() throws {
        for mode in ReminderMode.allCases {
            let preference = MedicationReminderPreference(
                intervalHours: 6,
                mode: mode,
                referencePoint: .now
            )
            let data = try JSONEncoder().encode(preference)
            let decoded = try JSONDecoder().decode(MedicationReminderPreference.self, from: data)
            #expect(decoded.mode == mode)
        }
    }

    @Test
    func encodesAndDecodesAllReferencePoints() throws {
        for point in ReminderReferencePoint.allCases {
            let preference = MedicationReminderPreference(
                intervalHours: 2,
                mode: .nextDueDose,
                referencePoint: point
            )
            let data = try JSONEncoder().encode(preference)
            let decoded = try JSONDecoder().decode(MedicationReminderPreference.self, from: data)
            #expect(decoded.referencePoint == point)
        }
    }
}

@MainActor
struct ScheduleMedicationReminderUseCaseTests {
    @Test
    func schedulesNotificationWhenFireDateIsInFuture() async {
        let spy = NotificationManagerSpy()
        let store = InMemoryMedicationReminderPreferenceStore()
        let childID = UUID()
        let now = Date(timeIntervalSince1970: 1_000)
        let occurredAt = Date(timeIntervalSince1970: 900)
        let preference = MedicationReminderPreference(
            intervalHours: 4,
            mode: .safeToGive,
            referencePoint: .doseTime
        )

        await ScheduleMedicationReminderUseCase.execute(
            input: .init(
                childID: childID,
                childName: "Poppy",
                medicineName: "Calpol",
                preference: preference,
                occurredAt: occurredAt,
                now: now
            ),
            notificationManager: spy,
            preferenceStore: store
        )

        // occurredAt (900) + 4h (14_400) = 15_300, which is > now (1_000)
        #expect(spy.scheduledCount == 1)
    }

    @Test
    func skipsSchedulingWhenFireDateIsInPast() async {
        let spy = NotificationManagerSpy()
        let store = InMemoryMedicationReminderPreferenceStore()
        let childID = UUID()
        let now = Date(timeIntervalSince1970: 100_000)
        let occurredAt = Date(timeIntervalSince1970: 1_000)
        let preference = MedicationReminderPreference(
            intervalHours: 4,
            mode: .safeToGive,
            referencePoint: .doseTime
        )

        await ScheduleMedicationReminderUseCase.execute(
            input: .init(
                childID: childID,
                childName: "Poppy",
                medicineName: "Calpol",
                preference: preference,
                occurredAt: occurredAt,
                now: now
            ),
            notificationManager: spy,
            preferenceStore: store
        )

        // occurredAt (1_000) + 4h (14_400) = 15_400, which is < now (100_000)
        #expect(spy.scheduledCount == 0)
    }

    @Test
    func savesPreferenceToStoreOnSuccess() async {
        let spy = NotificationManagerSpy()
        let store = InMemoryCapturingPreferenceStore()
        let childID = UUID()
        let now = Date(timeIntervalSince1970: 1_000)
        let occurredAt = Date(timeIntervalSince1970: 900)
        let preference = MedicationReminderPreference(
            intervalHours: 6,
            mode: .nextDueDose,
            referencePoint: .now
        )

        await ScheduleMedicationReminderUseCase.execute(
            input: .init(
                childID: childID,
                childName: "Poppy",
                medicineName: "Calpol",
                preference: preference,
                occurredAt: occurredAt,
                now: now
            ),
            notificationManager: spy,
            preferenceStore: store
        )

        let saved = store.preference(for: "Calpol", childID: childID)
        #expect(saved == preference)
    }

    @Test
    func usesNowAsReferenceWhenReferencePointIsNow() async {
        let spy = NotificationManagerSpy()
        let store = InMemoryMedicationReminderPreferenceStore()
        let childID = UUID()
        let now = Date(timeIntervalSince1970: 1_000)
        // occurredAt is far in the past; with doseTime reference this would be in the past
        let occurredAt = Date(timeIntervalSince1970: 100)
        let preference = MedicationReminderPreference(
            intervalHours: 4,
            mode: .safeToGive,
            referencePoint: .now
        )

        await ScheduleMedicationReminderUseCase.execute(
            input: .init(
                childID: childID,
                childName: "Poppy",
                medicineName: "Calpol",
                preference: preference,
                occurredAt: occurredAt,
                now: now
            ),
            notificationManager: spy,
            preferenceStore: store
        )

        // now (1_000) + 4h (14_400) = 15_400 > now — should schedule
        #expect(spy.scheduledCount == 1)
    }

    @Test
    func cancelUseCaseCancelsNotification() async {
        let spy = NotificationManagerSpy()
        let childID = UUID()

        await CancelMedicationReminderUseCase.execute(
            childID: childID,
            medicineName: "Calpol",
            notificationManager: spy
        )

        #expect(spy.cancelledCount == 1)
    }
}

// MARK: - Test doubles

@MainActor
private final class NotificationManagerSpy: LocalNotificationManaging {
    private(set) var scheduledCount = 0
    private(set) var cancelledCount = 0

    func isAuthorizedForNotifications() async -> Bool { true }
    func requestAuthorizationIfNeeded() async -> Bool { true }
    func scheduleRemoteSyncNotification(_ content: RemoteCaregiverNotificationContent) async {}
    func scheduleSleepDriftNotification(childID: UUID, childName: String, fireAfter: TimeInterval) async {}
    func cancelSleepDriftNotification(childID: UUID) async {}
    func scheduleInactivityDriftNotification(childID: UUID, childName: String, fireAfter: TimeInterval) async {}
    func cancelInactivityDriftNotification(childID: UUID) async {}
    func pendingDriftNotifications() async -> [PendingDriftNotification] { [] }

    func scheduleMedicationReminderNotification(childID: UUID, childName: String, medicineName: String, mode: ReminderMode, intervalHours: Int, fireAt: Date) async {
        scheduledCount += 1
    }

    func cancelMedicationReminderNotification(childID: UUID, medicineName: String) async {
        cancelledCount += 1
    }

    func pendingMedicationReminderNotifications() async -> [PendingMedicationReminder] { [] }
}

@MainActor
private final class InMemoryCapturingPreferenceStore: MedicationReminderPreferenceStore {
    private var storage: [String: MedicationReminderPreference] = [:]

    func preference(for medicineName: String, childID: UUID) -> MedicationReminderPreference? {
        storage[key(medicineName: medicineName, childID: childID)]
    }

    func savePreference(_ preference: MedicationReminderPreference, for medicineName: String, childID: UUID) {
        storage[key(medicineName: medicineName, childID: childID)] = preference
    }

    private func key(medicineName: String, childID: UUID) -> String {
        "\(childID.uuidString).\(medicineName.lowercased())"
    }
}
