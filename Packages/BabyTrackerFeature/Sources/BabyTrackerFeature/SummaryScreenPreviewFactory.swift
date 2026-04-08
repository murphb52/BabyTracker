import BabyTrackerDomain
import Foundation

@MainActor
enum SummaryScreenPreviewFactory {
    static var summaryViewModel: SummaryViewModel {
        SummaryViewModel(events: sampleEvents)
    }

    // swiftlint:disable function_body_length
    private static var sampleEvents: [BabyEvent] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        let childID = UUID()
        let userID = UUID()
        let now = Date()
        let today = calendar.startOfDay(for: now)

        func dateToday(hour: Int, minute: Int = 0) -> Date {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) ?? now
        }

        func dateOffset(days: Int, hour: Int, minute: Int = 0) -> Date {
            guard let day = calendar.date(byAdding: .day, value: days, to: today) else { return now }
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? now
        }

        var events: [BabyEvent] = []

        // MARK: Today events

        // Bottle feeds
        let bottleTimes: [(Int, Int, MilkType?)] = [
            (7, 0, .formula),
            (10, 30, .formula),
            (14, 0, .breastMilk),
            (17, 30, .formula),
        ]
        for (hour, minute, milkType) in bottleTimes {
            let t = dateToday(hour: hour, minute: minute)
            events.append(.bottleFeed(
                try! BottleFeedEvent(
                    metadata: EventMetadata(childID: childID, occurredAt: t, createdAt: t, createdBy: userID),
                    amountMilliliters: 150,
                    milkType: milkType
                )
            ))
        }

        // Breast feeds
        let breastEnd1 = dateToday(hour: 8, minute: 30)
        events.append(.breastFeed(
            try! BreastFeedEvent(
                metadata: EventMetadata(childID: childID, occurredAt: breastEnd1, createdAt: breastEnd1, createdBy: userID),
                side: .left,
                startedAt: breastEnd1.addingTimeInterval(-1_200),
                endedAt: breastEnd1
            )
        ))
        let breastEnd2 = dateToday(hour: 12, minute: 0)
        events.append(.breastFeed(
            try! BreastFeedEvent(
                metadata: EventMetadata(childID: childID, occurredAt: breastEnd2, createdAt: breastEnd2, createdBy: userID),
                side: .both,
                startedAt: breastEnd2.addingTimeInterval(-1_800),
                endedAt: breastEnd2
            )
        ))

        // Sleep events today
        let napEnd1 = dateToday(hour: 9, minute: 30)
        events.append(.sleep(
            try! SleepEvent(
                metadata: EventMetadata(childID: childID, occurredAt: napEnd1, createdAt: napEnd1, createdBy: userID),
                startedAt: napEnd1.addingTimeInterval(-3_600),
                endedAt: napEnd1
            )
        ))
        let napEnd2 = dateToday(hour: 13, minute: 30)
        events.append(.sleep(
            try! SleepEvent(
                metadata: EventMetadata(childID: childID, occurredAt: napEnd2, createdAt: napEnd2, createdBy: userID),
                startedAt: napEnd2.addingTimeInterval(-2_700),
                endedAt: napEnd2
            )
        ))

        // Nappies today
        let nappyData: [(Int, Int, NappyType)] = [
            (7, 30, .wee),
            (11, 0, .mixed),
            (15, 0, .poo),
            (18, 0, .wee),
        ]
        for (hour, minute, type) in nappyData {
            let t = dateToday(hour: hour, minute: minute)
            events.append(.nappy(
                try! NappyEvent(
                    metadata: EventMetadata(childID: childID, occurredAt: t, createdAt: t, createdBy: userID),
                    type: type,
                    peeVolume: (type == .wee || type == .mixed) ? .medium : nil,
                    pooVolume: (type == .poo || type == .mixed) ? .medium : nil,
                    pooColor: (type == .poo || type == .mixed) ? .yellow : nil
                )
            ))
        }

        // MARK: Historical events (past 7 days) for average line

        for dayOffset in 1...7 {
            let neg = -dayOffset

            // 2 bottle feeds per historical day
            for hour in [7, 14] {
                let t = dateOffset(days: neg, hour: hour)
                events.append(.bottleFeed(
                    try! BottleFeedEvent(
                        metadata: EventMetadata(childID: childID, occurredAt: t, createdAt: t, createdBy: userID),
                        amountMilliliters: 140,
                        milkType: .formula
                    )
                ))
            }

            // 1 breast feed per historical day
            let bEnd = dateOffset(days: neg, hour: 9)
            events.append(.breastFeed(
                try! BreastFeedEvent(
                    metadata: EventMetadata(childID: childID, occurredAt: bEnd, createdAt: bEnd, createdBy: userID),
                    side: .left,
                    startedAt: bEnd.addingTimeInterval(-900),
                    endedAt: bEnd
                )
            ))

            // 1 sleep per historical day
            let sEnd = dateOffset(days: neg, hour: 10)
            events.append(.sleep(
                try! SleepEvent(
                    metadata: EventMetadata(childID: childID, occurredAt: sEnd, createdAt: sEnd, createdBy: userID),
                    startedAt: sEnd.addingTimeInterval(-3_600),
                    endedAt: sEnd
                )
            ))

            // 2 nappies per historical day
            for hour in [8, 15] {
                let t = dateOffset(days: neg, hour: hour)
                events.append(.nappy(
                    try! NappyEvent(
                        metadata: EventMetadata(childID: childID, occurredAt: t, createdAt: t, createdBy: userID),
                        type: .wee,
                        peeVolume: .medium
                    )
                ))
            }
        }

        return events
    }
    // swiftlint:enable function_body_length
}
