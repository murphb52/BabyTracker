import BabyTrackerDomain
import SwiftUI

public struct CurrentStatusCardView: View {
    let status: CurrentStatusCardViewState

    public init(status: CurrentStatusCardViewState) {
        self.status = status
    }

    private var displayKinds: [BabyEventKind] {
        status.visibleEventKinds.filter { kind in
            kind != .sleep || status.lastSleep?.isActive != true
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(displayKinds.enumerated()), id: \.element) { index, kind in
                let row = status.row(for: kind)

                statusRow(
                    title: row?.title ?? BuildCurrentStatusViewStateUseCase.rowTitle(for: kind),
                    subtitle: row?.detailText,
                    systemImage: BabyEventStyle.systemImage(for: kind),
                    iconTint: BabyEventStyle.accentColor(for: kind),
                    identifier: accessibilityIdentifier(for: kind)
                ) {
                    if let row {
                        relativeTimeText(for: row.elapsedSinceDate)
                    } else {
                        Text(BuildCurrentStatusViewStateUseCase.emptyValueText(for: kind))
                    }
                }

                if index < displayKinds.count - 1 {
                    Divider()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.35), value: displayKinds)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("current-status-card")
    }

    private func accessibilityIdentifier(for kind: BabyEventKind) -> String {
        "current-status-\(kind.rawValue)"
    }

    private func statusRow<Value: View>(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        iconTint: Color,
        identifier: String,
        @ViewBuilder value: () -> Value
    ) -> some View {
        HStack(alignment: subtitle == nil ? .firstTextBaseline : .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(iconTint)
                .frame(width: 18)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            value()
                .font(.headline)
                .multilineTextAlignment(.trailing)
                .accessibilityIdentifier(identifier)
        }
    }

    private func relativeTimeText(for date: Date) -> some View {
        TimelineView(.everyMinute) { _ in
            Text(ElapsedTimeFormatter.string(from: date))
        }
    }
}

#Preview("Active sleep (sleep row hidden)") {
    CurrentStatusCardView(
        status: CurrentStatusCardViewState(
            visibleEventKinds: BabyEventKind.allCases,
            rows: [
                CurrentStatusRowViewState(
                    kind: .breastFeed,
                    title: "Last breast feed",
                    detailText: "20 min • Left",
                    elapsedSinceDate: Date().addingTimeInterval(-5_400),
                    emptyValueText: "No feeds yet"
                ),
                CurrentStatusRowViewState(
                    kind: .bottleFeed,
                    title: "Last bottle feed",
                    detailText: "120 mL • Formula",
                    elapsedSinceDate: Date().addingTimeInterval(-9_000),
                    emptyValueText: "No feeds yet"
                ),
                CurrentStatusRowViewState(
                    kind: .nappy,
                    title: "Last nappy",
                    detailText: "Poo • Medium • Yellow",
                    elapsedSinceDate: Date().addingTimeInterval(-7_200),
                    emptyValueText: "No nappies yet"
                ),
                CurrentStatusRowViewState(
                    kind: .bath,
                    title: "Last bath",
                    detailText: "Shampoo • Soap",
                    elapsedSinceDate: Date().addingTimeInterval(-10_200),
                    emptyValueText: "No baths yet"
                ),
            ],
            lastSleep: LastSleepSummaryViewState(
                isActive: true,
                startedAt: Date().addingTimeInterval(-4_500),
                endedAt: nil
            )
        )
    )
    .padding()
}

#Preview("Mixed kinds including Bath") {
    CurrentStatusCardView(
        status: CurrentStatusCardViewState(
            visibleEventKinds: BabyEventKind.allCases,
            rows: [
                CurrentStatusRowViewState(
                    kind: .bath,
                    title: "Last bath",
                    detailText: "Bath only",
                    elapsedSinceDate: Date().addingTimeInterval(-1_800),
                    emptyValueText: "No baths yet"
                ),
                CurrentStatusRowViewState(
                    kind: .breastFeed,
                    title: "Last breast feed",
                    detailText: "15 min • Right",
                    elapsedSinceDate: Date().addingTimeInterval(-3_600),
                    emptyValueText: "No feeds yet"
                ),
                CurrentStatusRowViewState(
                    kind: .bottleFeed,
                    title: "Last bottle feed",
                    detailText: "180 mL • Breast Milk",
                    elapsedSinceDate: Date().addingTimeInterval(-6_300),
                    emptyValueText: "No feeds yet"
                ),
                CurrentStatusRowViewState(
                    kind: .sleep,
                    title: "Last sleep",
                    detailText: "2 hr",
                    elapsedSinceDate: Date().addingTimeInterval(-10_800),
                    emptyValueText: "No sleep yet"
                ),
                CurrentStatusRowViewState(
                    kind: .nappy,
                    title: "Last nappy",
                    detailText: "Pee • Light",
                    elapsedSinceDate: Date().addingTimeInterval(-5_400),
                    emptyValueText: "No nappies yet"
                ),
            ],
            lastSleep: LastSleepSummaryViewState(
                isActive: false,
                startedAt: Date().addingTimeInterval(-18_000),
                endedAt: Date().addingTimeInterval(-10_800)
            )
        )
    )
    .padding()
}

#Preview("No data") {
    CurrentStatusCardView(
        status: CurrentStatusCardViewState(
            visibleEventKinds: [.bath, .bottleFeed, .sleep, .nappy],
            rows: [],
            lastSleep: nil
        )
    )
    .padding()
}
