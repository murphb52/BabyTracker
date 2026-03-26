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
public enum NestEventExport: Codable, Sendable {
    case breastFeed(NestBreastFeedExport)
    case bottleFeed(NestBottleFeedExport)
    case sleep(NestSleepExport)
    case nappy(NestNappyExport)

    private enum TypeKey: String, CodingKey {
        case type
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: TypeKey.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "breastFeed":
            self = .breastFeed(try NestBreastFeedExport(from: decoder))
        case "bottleFeed":
            self = .bottleFeed(try NestBottleFeedExport(from: decoder))
        case "sleep":
            self = .sleep(try NestSleepExport(from: decoder))
        case "nappy":
            self = .nappy(try NestNappyExport(from: decoder))
        default:
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unknown event type: \(type)")
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .breastFeed(let e):
            try e.encode(to: encoder)
            var c = encoder.container(keyedBy: TypeKey.self)
            try c.encode("breastFeed", forKey: .type)
        case .bottleFeed(let e):
            try e.encode(to: encoder)
            var c = encoder.container(keyedBy: TypeKey.self)
            try c.encode("bottleFeed", forKey: .type)
        case .sleep(let e):
            try e.encode(to: encoder)
            var c = encoder.container(keyedBy: TypeKey.self)
            try c.encode("sleep", forKey: .type)
        case .nappy(let e):
            try e.encode(to: encoder)
            var c = encoder.container(keyedBy: TypeKey.self)
            try c.encode("nappy", forKey: .type)
        }
    }
}

// MARK: - Per-event structs

public struct NestBreastFeedExport: Codable, Sendable {
    public let id: UUID
    public let occurredAt: Date
    public let notes: String
    public let side: BreastSide?
    public let startedAt: Date
    public let endedAt: Date
    public let leftDurationSeconds: Int?
    public let rightDurationSeconds: Int?
}

public struct NestBottleFeedExport: Codable, Sendable {
    public let id: UUID
    public let occurredAt: Date
    public let notes: String
    public let amountMilliliters: Int
    public let milkType: MilkType?
}

public struct NestSleepExport: Codable, Sendable {
    public let id: UUID
    public let occurredAt: Date
    public let notes: String
    public let startedAt: Date
    public let endedAt: Date
}

public struct NestNappyExport: Codable, Sendable {
    public let id: UUID
    public let occurredAt: Date
    public let notes: String
    public let nappyType: NappyType
    public let peeVolume: NappyVolume?
    public let pooVolume: NappyVolume?
    public let pooColor: PooColor?
}
