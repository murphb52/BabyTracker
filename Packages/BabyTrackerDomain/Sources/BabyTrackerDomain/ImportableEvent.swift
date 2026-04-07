import Foundation

/// Represents a fully-parsed CSV row, typed and ready to be saved as a domain event.
public enum ImportableEvent: Equatable, Sendable, Identifiable {
    case bottleFeed(BottleFeedImport)
    case breastFeed(BreastFeedImport)
    case sleep(SleepImport)
    case nappy(NappyImport)

    public var id: UUID { metadata.id }

    public var metadata: ImportEventMetadata {
        switch self {
        case .bottleFeed(let e): return e.metadata
        case .breastFeed(let e): return e.metadata
        case .sleep(let e): return e.metadata
        case .nappy(let e): return e.metadata
        }
    }

    public var occurredAt: Date { metadata.occurredAt }

    public var kind: BabyEventKind {
        switch self {
        case .bottleFeed: return .bottleFeed
        case .breastFeed: return .breastFeed
        case .sleep: return .sleep
        case .nappy: return .nappy
        }
    }

    public var displayTitle: String {
        switch self {
        case .bottleFeed(let e):
            var parts = ["\(e.amountMilliliters)ml"]
            if let milkType = e.milkType {
                parts.insert(milkType.displayName, at: 0)
            }
            return parts.joined(separator: " ")
        case .breastFeed(let e):
            let durationText = DurationText.short(minutes: e.durationMinutes)
            if let side = e.side {
                return "\(side.displayName) · \(durationText)"
            }
            return durationText
        case .sleep(let e):
            let durationMinutes = max(0, Int(e.endedAt.timeIntervalSince(e.startedAt) / 60))
            return DurationText.short(minutes: durationMinutes)
        case .nappy(let e):
            return e.type.displayName
        }
    }

    public var eventKindLabel: String {
        switch self {
        case .bottleFeed: return "Bottle Feed"
        case .breastFeed: return "Breast Feed"
        case .sleep: return "Sleep"
        case .nappy: return "Nappy"
        }
    }
}

// MARK: - Import sub-types

public struct ImportEventMetadata: Equatable, Sendable {
    public let id: UUID
    public let occurredAt: Date
    public let notes: String?

    public init(occurredAt: Date, notes: String? = nil) {
        self.id = UUID()
        self.occurredAt = occurredAt
        self.notes = notes
    }
}

public struct BottleFeedImport: Equatable, Sendable {
    public let metadata: ImportEventMetadata
    public let amountMilliliters: Int
    public let milkType: MilkType?

    public init(metadata: ImportEventMetadata, amountMilliliters: Int, milkType: MilkType?) {
        self.metadata = metadata
        self.amountMilliliters = amountMilliliters
        self.milkType = milkType
    }
}

public struct BreastFeedImport: Equatable, Sendable {
    public let metadata: ImportEventMetadata
    public let startedAt: Date
    public let endedAt: Date
    public let durationMinutes: Int
    public let side: BreastSide?
    public let leftDurationSeconds: Int?
    public let rightDurationSeconds: Int?

    public init(
        metadata: ImportEventMetadata,
        startedAt: Date,
        endedAt: Date,
        durationMinutes: Int,
        side: BreastSide?,
        leftDurationSeconds: Int?,
        rightDurationSeconds: Int?
    ) {
        self.metadata = metadata
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationMinutes = durationMinutes
        self.side = side
        self.leftDurationSeconds = leftDurationSeconds
        self.rightDurationSeconds = rightDurationSeconds
    }
}

public struct SleepImport: Equatable, Sendable {
    public let metadata: ImportEventMetadata
    public let startedAt: Date
    public let endedAt: Date

    public init(metadata: ImportEventMetadata, startedAt: Date, endedAt: Date) {
        self.metadata = metadata
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}

public struct NappyImport: Equatable, Sendable {
    public let metadata: ImportEventMetadata
    public let type: NappyType
    public let peeVolume: NappyVolume?
    public let pooVolume: NappyVolume?
    public let pooColor: PooColor?

    public init(
        metadata: ImportEventMetadata,
        type: NappyType,
        peeVolume: NappyVolume?,
        pooVolume: NappyVolume?,
        pooColor: PooColor?
    ) {
        self.metadata = metadata
        self.type = type
        self.peeVolume = peeVolume
        self.pooVolume = pooVolume
        self.pooColor = pooColor
    }
}

// MARK: - Display helpers

private extension MilkType {
    var displayName: String {
        switch self {
        case .breastMilk: return "Breast Milk"
        case .formula: return "Formula"
        case .mixed: return "Mixed"
        case .other: return "Other"
        }
    }
}

private extension BreastSide {
    var displayName: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        case .both: return "Both"
        }
    }
}

private extension NappyType {
    var displayName: String {
        switch self {
        case .dry: return "Dry"
        case .wee: return "Wee"
        case .poo: return "Poo"
        case .mixed: return "Mixed"
        }
    }
}
