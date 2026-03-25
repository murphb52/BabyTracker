import Foundation

public struct NappyEntry: Equatable, Sendable {
    public var type: NappyType
    public var peeVolume: NappyVolume?
    public var pooVolume: NappyVolume?
    public var pooColor: PooColor?

    public init(
        type: NappyType,
        peeVolume: NappyVolume? = nil,
        pooVolume: NappyVolume? = nil,
        pooColor: PooColor? = nil
    ) throws {
        guard Self.supportsPooColor(for: type) || pooColor == nil else {
            throw NappyEntryError.pooColorRequiresPooOrMixed
        }

        self.type = type
        self.peeVolume = peeVolume
        self.pooVolume = pooVolume
        self.pooColor = pooColor
    }

    public static func supportsPooColor(for type: NappyType) -> Bool {
        switch type {
        case .poo, .mixed:
            true
        case .dry, .wee:
            false
        }
    }

    public static func supportsPeeVolume(for type: NappyType) -> Bool {
        switch type {
        case .wee, .mixed:
            true
        case .dry, .poo:
            false
        }
    }

    public static func supportsPooVolume(for type: NappyType) -> Bool {
        switch type {
        case .poo, .mixed:
            true
        case .dry, .wee:
            false
        }
    }
}
