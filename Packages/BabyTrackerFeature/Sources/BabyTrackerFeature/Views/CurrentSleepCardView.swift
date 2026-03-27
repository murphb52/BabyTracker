import SwiftUI

public struct CurrentSleepCardView: View {
    let sleep: CurrentSleepCardViewState
    let stopSleep: () -> Void

    public init(
        sleep: CurrentSleepCardViewState,
        stopSleep: @escaping () -> Void
    ) {
        self.sleep = sleep
        self.stopSleep = stopSleep
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Current Sleep")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TimelineView(.everyMinute) { context in
                Text(durationText(from: sleep.startedAt, to: context.date))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .accessibilityIdentifier("current-sleep-duration")
            }

            Text("Asleep since \(sleep.startedAt, format: .dateTime.hour().minute())")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("current-sleep-started-at")

            Button("Stop") {
                stopSleep()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("current-sleep-stop-button")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("current-sleep-card")
    }

    private func durationText(from startedAt: Date, to currentDate: Date) -> String {
        let seconds = max(0, Int(currentDate.timeIntervalSince(startedAt)))
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }

        return "\(minutes)m"
    }
}
