import Foundation

public struct LastNappySummaryViewState: Equatable, Sendable {
    public let title: String
    public let detailText: String?
    public let occurredAt: Date

    public init(
        title: String,
        detailText: String?,
        occurredAt: Date
    ) {
        self.title = title
        self.detailText = detailText
        self.occurredAt = occurredAt
    }
}
