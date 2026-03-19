import Foundation

public struct NappyEntry: Equatable, Sendable {
    public var type: NappyType
    public var intensity: NappyIntensity?
    public var pooColor: PooColor?

    public init(
        type: NappyType,
        intensity: NappyIntensity? = nil,
        pooColor: PooColor? = nil
    ) throws {
        guard Self.supportsPooColor(for: type) || pooColor == nil else {
            throw NappyEntryError.pooColorRequiresPooOrMixed
        }

        self.type = type
        self.intensity = intensity
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
}
