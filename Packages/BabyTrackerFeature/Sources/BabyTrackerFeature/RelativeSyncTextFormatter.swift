import Foundation

public enum RelativeSyncTextFormatter {
    public static func lastSyncedText(
        for date: Date,
        relativeTo referenceDate: Date
    ) -> String {
        guard date <= referenceDate else {
            return "Last Synced: just now"
        }

        let formatter = RelativeDateTimeFormatter()
        let relativeText = formatter.localizedString(for: date, relativeTo: referenceDate)
        return "Last Synced: \(relativeText)"
    }
}
