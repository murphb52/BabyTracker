import BabyTrackerDomain
import BabyTrackerFeature
import Foundation
import Testing

struct CloudKitRecordMapperTests {
    @Test
    func breastFeedMapperRoundTripsOptionalAndBothSides() throws {
        let childID = UUID()
        let userID = UUID()
        let noSideEnd = Date(timeIntervalSince1970: 1_000)
        let bothSidesEnd = Date(timeIntervalSince1970: 2_000)

        let noSideFeed = try BreastFeedEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: noSideEnd,
                createdAt: noSideEnd,
                createdBy: userID
            ),
            side: nil,
            startedAt: noSideEnd.addingTimeInterval(-900),
            endedAt: noSideEnd
        )
        let bothSidesFeed = try BreastFeedEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: bothSidesEnd,
                createdAt: bothSidesEnd,
                createdBy: userID
            ),
            side: .both,
            startedAt: bothSidesEnd.addingTimeInterval(-1_200),
            endedAt: bothSidesEnd
        )

        let noSideRecordField = FeedCloudKitMapperProbe.breastFeedSideField(for: noSideFeed)
        let bothSidesRecordField = FeedCloudKitMapperProbe.breastFeedSideField(for: bothSidesFeed)

        #expect(noSideRecordField == nil)
        #expect(bothSidesRecordField == "both")

        let reloadedNoSideRecord = try FeedCloudKitMapperProbe.roundTrip(noSideFeed)
        let reloadedBothSidesRecord = try FeedCloudKitMapperProbe.roundTrip(bothSidesFeed)

        #expect(reloadedNoSideRecord.side == nil)
        #expect(reloadedBothSidesRecord.side == .both)
    }
}
