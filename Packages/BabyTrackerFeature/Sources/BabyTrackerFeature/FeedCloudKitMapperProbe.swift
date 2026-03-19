import BabyTrackerDomain
import BabyTrackerSync
import Foundation

public enum FeedCloudKitMapperProbe {
    public enum Error: Swift.Error {
        case unexpectedEventKind
    }

    public static func breastFeedSideField(
        for event: BreastFeedEvent
    ) -> String? {
        let zoneID = CloudKitRecordNames.zoneID(
            for: event.metadata.childID,
            ownerName: "probe-owner"
        )
        let record = CloudKitRecordMapper.eventRecord(
            from: .breastFeed(event),
            zoneID: zoneID
        )

        return record["side"] as? String
    }

    public static func roundTrip(
        _ event: BreastFeedEvent
    ) throws -> BreastFeedEvent {
        let zoneID = CloudKitRecordNames.zoneID(
            for: event.metadata.childID,
            ownerName: "probe-owner"
        )
        let record = CloudKitRecordMapper.eventRecord(
            from: .breastFeed(event),
            zoneID: zoneID
        )
        let mappedEvent = try CloudKitRecordMapper.event(from: record)

        guard case let .breastFeed(value) = mappedEvent else {
            throw Error.unexpectedEventKind
        }

        return value
    }
}
