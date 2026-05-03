import BabyTrackerDomain
import Foundation

public struct CurrentStatusRowViewState: Equatable, Sendable {
    public let kind: BabyEventKind
    public let title: String
    public let detailText: String?
    public let elapsedSinceDate: Date
    public let emptyValueText: String

    public init(
        kind: BabyEventKind,
        title: String,
        detailText: String?,
        elapsedSinceDate: Date,
        emptyValueText: String
    ) {
        self.kind = kind
        self.title = title
        self.detailText = detailText
        self.elapsedSinceDate = elapsedSinceDate
        self.emptyValueText = emptyValueText
    }
}
