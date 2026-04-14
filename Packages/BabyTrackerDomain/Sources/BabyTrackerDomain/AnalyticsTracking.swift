public struct AnalyticsEvent: Sendable, Equatable {
    public let name: String
    public let parameters: [String: String]

    public init(name: String, parameters: [String: String] = [:]) {
        self.name = name
        self.parameters = parameters
    }
}

public protocol AnalyticsTracking: Sendable {
    func track(_ event: AnalyticsEvent)
}

