import BabyTrackerDomain
import Foundation

public enum ScheduleMedicationReminderUseCase {
    public struct Input {
        public let childID: UUID
        public let childName: String
        public let medicineName: String
        public let preference: MedicationReminderPreference
        public let occurredAt: Date
        public let now: Date

        public init(
            childID: UUID,
            childName: String,
            medicineName: String,
            preference: MedicationReminderPreference,
            occurredAt: Date,
            now: Date = .now
        ) {
            self.childID = childID
            self.childName = childName
            self.medicineName = medicineName
            self.preference = preference
            self.occurredAt = occurredAt
            self.now = now
        }
    }

    @MainActor
    public static func execute(
        input: Input,
        notificationManager: any LocalNotificationManaging,
        preferenceStore: any MedicationReminderPreferenceStore
    ) async {
        let referenceDate = input.preference.referencePoint == .doseTime ? input.occurredAt : input.now
        let fireAt = referenceDate.addingTimeInterval(TimeInterval(input.preference.intervalHours) * 3_600)
        guard fireAt > input.now else { return }

        preferenceStore.savePreference(input.preference, for: input.medicineName, childID: input.childID)

        await notificationManager.scheduleMedicationReminderNotification(
            childID: input.childID,
            childName: input.childName,
            medicineName: input.medicineName,
            mode: input.preference.mode,
            intervalHours: input.preference.intervalHours,
            fireAt: fireAt
        )
    }
}
