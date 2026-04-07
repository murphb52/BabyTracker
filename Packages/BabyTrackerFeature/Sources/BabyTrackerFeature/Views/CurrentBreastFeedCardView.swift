import BabyTrackerDomain
import SwiftUI

public struct CurrentBreastFeedCardView: View {
    let session: CurrentBreastFeedCardViewState
    let endBreastFeed: () -> Void

    public init(session: CurrentBreastFeedCardViewState, endBreastFeed: @escaping () -> Void) {
        self.session = session
        self.endBreastFeed = endBreastFeed
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: BabyEventStyle.systemImage(for: .breastFeed))
                .font(.title3.weight(.semibold))
                .foregroundStyle(BabyEventStyle.accentColor(for: .breastFeed))
                .frame(width: 44, height: 44)
                .background(BabyEventStyle.backgroundColor(for: .breastFeed), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(durationText(from: session.startedAt, to: context.date))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(BabyEventStyle.accentColor(for: .breastFeed))
                        .accessibilityIdentifier("current-breast-feed-duration")
                }

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("current-breast-feed-started-at")
            }

            Spacer(minLength: 8)

            Button("End") {
                endBreastFeed()
            }
            .buttonStyle(.borderedProminent)
            .tint(BabyEventStyle.accentColor(for: .breastFeed))
            .accessibilityIdentifier("current-breast-feed-end-button")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BabyEventStyle.backgroundColor(for: .breastFeed))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(BabyEventStyle.accentColor(for: .breastFeed).opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("current-breast-feed-card")
    }

    private var subtitle: String {
        if let side = session.side {
            return "Started \(sideLabel(side)) at \(session.startedAt, format: .dateTime.hour().minute())"
        }
        return "Started \(session.startedAt, format: .dateTime.hour().minute())"
    }

    private func sideLabel(_ side: BreastSide) -> String {
        switch side {
        case .left: "left"
        case .right: "right"
        case .both: "both sides"
        }
    }

    private func durationText(from startedAt: Date, to currentDate: Date) -> String {
        let seconds = max(0, Int(currentDate.timeIntervalSince(startedAt)))
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let remainingSeconds = seconds % 60

        return String(format: "%02dh %02dm %02ds", hours, minutes, remainingSeconds)
    }
}

#Preview {
    CurrentBreastFeedCardView(
        session: CurrentBreastFeedCardViewState(
            id: UUID(),
            startedAt: Date().addingTimeInterval(-1_200),
            side: .left
        ),
        endBreastFeed: {}
    )
    .padding()
}
