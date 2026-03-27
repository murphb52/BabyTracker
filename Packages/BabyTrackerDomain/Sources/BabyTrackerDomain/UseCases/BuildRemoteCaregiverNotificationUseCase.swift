import Foundation

public struct BuildRemoteCaregiverNotificationUseCase: Sendable {
    public struct Input: Sendable {
        public let changes: [RemoteCaregiverEventChange]

        public init(changes: [RemoteCaregiverEventChange]) {
            self.changes = changes
        }
    }

    private let formatTime: @Sendable (Date) -> String

    public init(formatTime: @escaping @Sendable (Date) -> String = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: $0)
    }) {
        self.formatTime = formatTime
    }

    public func execute(_ input: Input) -> RemoteCaregiverNotificationContent? {
        guard !input.changes.isEmpty else {
            return nil
        }

        if input.changes.count == 1, let change = input.changes.first {
            return .init(
                title: "Baby Tracker",
                body: message(for: change)
            )
        }

        let distinctCaregivers = Set(input.changes.map(\.actorDisplayName)).count
        if distinctCaregivers == 1, let caregiver = input.changes.first?.actorDisplayName {
            return .init(
                title: "Baby Tracker",
                body: "\(caregiver) logged \(input.changes.count) updates."
            )
        }

        return .init(
            title: "Baby Tracker",
            body: "\(input.changes.count) new updates from caregivers."
        )
    }

    private func message(for change: RemoteCaregiverEventChange) -> String {
        switch change.event {
        case let .sleep(event):
            if event.endedAt == nil {
                return "\(change.actorDisplayName) started a sleep timer."
            }

            return "\(change.actorDisplayName) logged a sleep at \(formatTime(event.metadata.occurredAt))."
        case let .nappy(event):
            return "\(change.actorDisplayName) logged a \(nappyDescriptor(for: event.type)) nappy at \(formatTime(event.metadata.occurredAt))."
        case let .bottleFeed(event):
            return "\(change.actorDisplayName) logged a bottle feed at \(formatTime(event.metadata.occurredAt))."
        case let .breastFeed(event):
            return "\(change.actorDisplayName) logged a breast feed at \(formatTime(event.metadata.occurredAt))."
        }
    }

    private func nappyDescriptor(for type: NappyType) -> String {
        switch type {
        case .dry:
            "dry"
        case .wee:
            "wet"
        case .poo:
            "dirty"
        case .mixed:
            "mixed"
        }
    }
}
