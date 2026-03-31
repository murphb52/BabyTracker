import BabyTrackerDomain
import BabyTrackerFeature
@testable import BabyTrackerSync
import CloudKit
import Foundation
import Testing

struct CloudKitRecordMapperTests {
    @Test
    func sharedHierarchyRecordsPointBackToChild() throws {
        let childID = UUID()
        let userID = UUID()
        let zoneID = CloudKitRecordNames.zoneID(
            for: childID,
            ownerName: "probe-owner"
        )
        let user = try UserIdentity(
            id: userID,
            displayName: "Alex Parent",
            createdAt: .now,
            cloudKitUserRecordName: "cloud-user"
        )
        let membership = Membership.owner(
            childID: childID,
            userID: userID,
            createdAt: .now
        )
        let event = try BottleFeedEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: .now,
                createdAt: .now,
                createdBy: userID
            ),
            amountMilliliters: 120
        )

        let expectedParentRecordID = CloudKitRecordNames.childRecordID(
            childID: childID,
            zoneID: zoneID
        )

        let userRecord = CloudKitRecordMapper.userRecord(
            from: user,
            childID: childID,
            zoneID: zoneID
        )
        let membershipRecord = CloudKitRecordMapper.membershipRecord(
            from: membership,
            zoneID: zoneID
        )
        let eventRecord = CloudKitRecordMapper.eventRecord(
            from: .bottleFeed(event),
            zoneID: zoneID
        )

        #expect(userRecord.parent?.recordID == expectedParentRecordID)
        #expect(membershipRecord.parent?.recordID == expectedParentRecordID)
        #expect(eventRecord.parent?.recordID == expectedParentRecordID)
    }

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

    @Test
    func nappyMapperRoundTripsOptionalFields() throws {
        let childID = UUID()
        let userID = UUID()
        let occurredAt = Date(timeIntervalSince1970: 3_000)
        let zoneID = CloudKitRecordNames.zoneID(
            for: childID,
            ownerName: "probe-owner"
        )
        let nappy = try NappyEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: occurredAt,
                createdAt: occurredAt,
                createdBy: userID
            ),
            type: .mixed,
            pooVolume: .medium,
            pooColor: .brown
        )

        let record = CloudKitRecordMapper.eventRecord(
            from: .nappy(nappy),
            zoneID: zoneID
        )

        #expect(record["type"] as? String == "mixed")
        #expect(record["pooVolume"] as? String == "medium")
        #expect(record["pooColor"] as? String == "brown")

        let mappedEvent = try CloudKitRecordMapper.event(from: record)

        switch mappedEvent {
        case let .nappy(event):
            #expect(event.type == .mixed)
            #expect(event.pooVolume == .medium)
            #expect(event.pooColor == .brown)
        default:
            Issue.record("Expected a nappy event")
        }
    }

    @Test
    func sleepMapperRoundTripsOpenEndedAndCompletedSessions() throws {
        let childID = UUID()
        let userID = UUID()
        let activeStart = Date(timeIntervalSince1970: 4_000)
        let completedEnd = Date(timeIntervalSince1970: 5_000)
        let zoneID = CloudKitRecordNames.zoneID(
            for: childID,
            ownerName: "probe-owner"
        )
        let activeSleep = try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: activeStart,
                createdAt: activeStart,
                createdBy: userID
            ),
            startedAt: activeStart
        )
        let completedSleep = try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: completedEnd,
                createdAt: completedEnd,
                createdBy: userID
            ),
            startedAt: completedEnd.addingTimeInterval(-1_800),
            endedAt: completedEnd
        )

        let activeRecord = CloudKitRecordMapper.eventRecord(
            from: .sleep(activeSleep),
            zoneID: zoneID
        )
        let completedRecord = CloudKitRecordMapper.eventRecord(
            from: .sleep(completedSleep),
            zoneID: zoneID
        )

        #expect(activeRecord["endedAt"] as? Date == nil)
        #expect(completedRecord["endedAt"] as? Date == completedEnd)

        let activeMappedEvent = try CloudKitRecordMapper.event(from: activeRecord)
        let completedMappedEvent = try CloudKitRecordMapper.event(from: completedRecord)

        switch activeMappedEvent {
        case let .sleep(event):
            #expect(event.startedAt == activeStart)
            #expect(event.endedAt == nil)
        default:
            Issue.record("Expected an active sleep event")
        }

        switch completedMappedEvent {
        case let .sleep(event):
            #expect(event.startedAt == completedSleep.startedAt)
            #expect(event.endedAt == completedEnd)
        default:
            Issue.record("Expected a completed sleep event")
        }
    }

    @Test
    func childMapperRoundTripsPreferredFeedVolumeUnit() throws {
        let child = try Child(
            name: "Poppy",
            createdBy: UUID(),
            preferredFeedVolumeUnit: .ounces
        )
        let zoneID = CloudKitRecordNames.zoneID(for: child.id, ownerName: "owner")

        let record = CloudKitRecordMapper.childRecord(from: child, zoneID: zoneID)
        let mappedChild = try CloudKitRecordMapper.child(from: record)

        #expect(mappedChild.preferredFeedVolumeUnit == .ounces)
    }

    @Test
    func childMapperRoundTripsImageAndUpdatedAt() throws {
        let updatedAt = Date(timeIntervalSince1970: 12_345)
        let imageData = Data([0x01, 0x02, 0x03])
        let child = try Child(
            name: "Robin",
            createdAt: Date(timeIntervalSince1970: 10_000),
            updatedAt: updatedAt,
            createdBy: UUID(),
            imageData: imageData
        )
        let zoneID = CloudKitRecordNames.zoneID(for: child.id, ownerName: "owner")

        let record = CloudKitRecordMapper.childRecord(from: child, zoneID: zoneID)
        let mappedChild = try CloudKitRecordMapper.child(from: record)

        #expect(record["updatedAt"] as? Date == updatedAt)
        #expect(mappedChild.updatedAt == updatedAt)
        #expect(mappedChild.imageData == imageData)
    }
}
