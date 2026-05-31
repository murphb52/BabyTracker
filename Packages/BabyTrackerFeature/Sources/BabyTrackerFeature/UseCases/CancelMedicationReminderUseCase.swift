import BabyTrackerDomain
import Foundation

public enum CancelMedicationReminderUseCase {
    @MainActor
    public static func execute(
        childID: UUID,
        medicineName: String,
        notificationManager: any LocalNotificationManaging
    ) async {
        await notificationManager.cancelMedicationReminderNotification(childID: childID, medicineName: medicineName)
    }
}
