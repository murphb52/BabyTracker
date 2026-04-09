import BabyTrackerFeature
import Foundation
import Testing

struct RelativeSyncTextFormatterTests {
    @Test
    func lastSyncedTextUsesAgoForPastDates() {
        let referenceDate = Date(timeIntervalSince1970: 1_000)
        let lastSyncedAt = Date(timeIntervalSince1970: 940)

        let text = RelativeSyncTextFormatter.lastSyncedText(
            for: lastSyncedAt,
            relativeTo: referenceDate
        )

        #expect(text.contains("Last Synced:"))
        #expect(text.contains("ago"))
    }

    @Test
    func lastSyncedTextClampsFutureDatesToJustNow() {
        let referenceDate = Date(timeIntervalSince1970: 1_000)
        let lastSyncedAt = Date(timeIntervalSince1970: 1_060)

        let text = RelativeSyncTextFormatter.lastSyncedText(
            for: lastSyncedAt,
            relativeTo: referenceDate
        )

        #expect(text == "Last Synced: just now")
    }
}
