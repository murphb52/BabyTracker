import Foundation

// MARK: - Top-level container

/// The root object for a Nest JSON export file.
public struct NestExportData: Codable, Sendable {
    public let version: Int
    public let exportedAt: Date
    public let child: NestChildExport
    public let events: [NestEventExport]

    public init(version: Int = 1, exportedAt: Date, child: NestChildExport, events: [NestEventExport]) {
        self.version = version
        self.exportedAt = exportedAt
        self.child = child
        self.events = events
    }
}

// MARK: - Child

public struct NestChildExport: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let birthDate: Date?

    public init(id: UUID, name: String, birthDate: Date?) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
    }
}

// MARK: - Event (type-discriminated union)

/// A single exported event. Encoded as a flat JSON object with a `"type"` discriminator key.
/// All serialisation is handled manually here so associated-value structs remain plain `Sendable` types.
public enum NestEventExport: Codable, Sendable {
    case breastFeed(NestBreastFeedExport)
    case bottleFeed(NestBottleFeedExport)
    case sleep(NestSleepExport)
    case nappy(NestNappyExport)

    private enum CodingKeys: String, CodingKey {
        case type
        case id, occurredAt, notes
        // breastFeed
        case side, startedAt, endedAt, leftDurationSeconds, rightDurationSeconds
        // bottleFeed
        case amountMilliliters, milkType
        // nappy
        case nappyType, peeVolume, pooVolume, pooColor
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        let id = try c.decode(UUID.self, forKey: .id)
        let occurredAt = try c.decode(Date.self, forKey: .occurredAt)
        let notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""

        switch type {
        case "breastFeed":
            self = .breastFeed(NestBreastFeedExport(
                id: id,
                occurredAt: occurredAt,
                notes: notes,
                side: try c.decodeIfPresent(BreastSide.self, forKey: .side),
                startedAt: try c.decode(Date.self, forKey: .startedAt),
                endedAt: try c.decode(Date.self, forKey: .endedAt),
                leftDurationSeconds: try c.decodeIfPresent(Int.self, forKey: .leftDurationSeconds),
                rightDurationSeconds: try c.decodeIfPresent(Int.self, forKey: .rightDurationSeconds)
            ))
        case "bottleFeed":
            self = .bottleFeed(NestBottleFeedExport(
                id: id,
                occurredAt: occurredAt,
                notes: notes,
                amountMilliliters: try c.decode(Int.self, forKey: .amountMilliliters),
                milkType: try c.decodeIfPresent(MilkType.self, forKey: .milkType)
            ))
        case "sleep":
            self = .sleep(NestSleepExport(
                id: id,
                occurredAt: occurredAt,
                notes: notes,
                startedAt: try c.decode(Date.self, forKey: .startedAt),
                endedAt: try c.decode(Date.self, forKey: .endedAt)
            ))
        case "nappy":
            self = .nappy(NestNappyExport(
                id: id,
                occurredAt: occurredAt,
                notes: notes,
                nappyType: try c.decode(NappyType.self, forKey: .nappyType),
                peeVolume: try c.decodeIfPresent(NappyVolume.self, forKey: .peeVolume),
                pooVolume: try c.decodeIfPresent(NappyVolume.self, forKey: .pooVolume),
                pooColor: try c.decodeIfPresent(PooColor.self, forKey: .pooColor)
            ))
        default:
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unknown event type: \(type)")
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .breastFeed(let e):
            try c.encode("breastFeed", forKey: .type)
            try c.encode(e.id, forKey: .id)
            try c.encode(e.occurredAt, forKey: .occurredAt)
            try c.encode(e.notes, forKey: .notes)
            try c.encodeIfPresent(e.side, forKey: .side)
            try c.encode(e.startedAt, forKey: .startedAt)
            try c.encode(e.endedAt, forKey: .endedAt)
            try c.encodeIfPresent(e.leftDurationSeconds, forKey: .leftDurationSeconds)
            try c.encodeIfPresent(e.rightDurationSeconds, forKey: .rightDurationSeconds)

        case .bottleFeed(let e):
            try c.encode("bottleFeed", forKey: .type)
            try c.encode(e.id, forKey: .id)
            try c.encode(e.occurredAt, forKey: .occurredAt)
            try c.encode(e.notes, forKey: .notes)
            try c.encode(e.amountMilliliters, forKey: .amountMilliliters)
            try c.encodeIfPresent(e.milkType, forKey: .milkType)

        case .sleep(let e):
            try c.encode("sleep", forKey: .type)
            try c.encode(e.id, forKey: .id)
            try c.encode(e.occurredAt, forKey: .occurredAt)
            try c.encode(e.notes, forKey: .notes)
            try c.encode(e.startedAt, forKey: .startedAt)
            try c.encode(e.endedAt, forKey: .endedAt)

        case .nappy(let e):
            try c.encode("nappy", forKey: .type)
            try c.encode(e.id, forKey: .id)
            try c.encode(e.occurredAt, forKey: .occurredAt)
            try c.encode(e.notes, forKey: .notes)
            try c.encode(e.nappyType, forKey: .nappyType)
            try c.encodeIfPresent(e.peeVolume, forKey: .peeVolume)
            try c.encodeIfPresent(e.pooVolume, forKey: .pooVolume)
            try c.encodeIfPresent(e.pooColor, forKey: .pooColor)
        }
    }
}

// MARK: - Per-event structs (plain data carriers — not Codable)

public struct NestBreastFeedExport: Sendable {
    public let id: UUID
    public let occurredAt: Date
    public let notes: String
    public let side: BreastSide?
    public let startedAt: Date
    public let endedAt: Date
    public let leftDurationSeconds: Int?
    public let rightDurationSeconds: Int?

    public init(id: UUID, occurredAt: Date, notes: String, side: BreastSide?, startedAt: Date, endedAt: Date, leftDurationSeconds: Int?, rightDurationSeconds: Int?) {
        self.id = id
        self.occurredAt = occurredAt
        self.notes = notes
        self.side = side
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.leftDurationSeconds = leftDurationSeconds
        self.rightDurationSeconds = rightDurationSeconds
    }
}

public struct NestBottleFeedExport: Sendable {
    public let id: UUID
    public let occurredAt: Date
    public let notes: String
    public let amountMilliliters: Int
    public let milkType: MilkType?

    public init(id: UUID, occurredAt: Date, notes: String, amountMilliliters: Int, milkType: MilkType?) {
        self.id = id
        self.occurredAt = occurredAt
        self.notes = notes
        self.amountMilliliters = amountMilliliters
        self.milkType = milkType
    }
}

public struct NestSleepExport: Sendable {
    public let id: UUID
    public let occurredAt: Date
    public let notes: String
    public let startedAt: Date
    public let endedAt: Date

    public init(id: UUID, occurredAt: Date, notes: String, startedAt: Date, endedAt: Date) {
        self.id = id
        self.occurredAt = occurredAt
        self.notes = notes
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}

public struct NestNappyExport: Sendable {
    public let id: UUID
    public let occurredAt: Date
    public let notes: String
    public let nappyType: NappyType
    public let peeVolume: NappyVolume?
    public let pooVolume: NappyVolume?
    public let pooColor: PooColor?

    public init(id: UUID, occurredAt: Date, notes: String, nappyType: NappyType, peeVolume: NappyVolume?, pooVolume: NappyVolume?, pooColor: PooColor?) {
        self.id = id
        self.occurredAt = occurredAt
        self.notes = notes
        self.nappyType = nappyType
        self.peeVolume = peeVolume
        self.pooVolume = pooVolume
        self.pooColor = pooColor
    }
}
