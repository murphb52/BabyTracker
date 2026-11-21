import Foundation

/// Whether the on-device assistant can answer questions on this device right now.
public enum AssistantAvailability: Equatable, Sendable {
    case available
    /// The device supports Apple Intelligence but the user has turned it off.
    case appleIntelligenceDisabled
    /// The hardware, region or language cannot run the on-device model.
    case deviceNotEligible
    /// The model is supported but still downloading or otherwise not ready.
    case modelNotReady

    public var isAvailable: Bool {
        self == .available
    }
}
