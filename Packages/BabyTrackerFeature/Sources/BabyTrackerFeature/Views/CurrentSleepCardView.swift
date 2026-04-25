import BabyTrackerDomain
import SwiftUI

public struct CurrentSleepCardView: View {
    let sleep: CurrentSleepCardViewState
    let stopSleep: () -> Void
    let logPastSleep: () -> Void

    public init(
        sleep: CurrentSleepCardViewState,
        stopSleep: @escaping () -> Void,
        logPastSleep: @escaping () -> Void
    ) {
        self.sleep = sleep
        self.stopSleep = stopSleep
        self.logPastSleep = logPastSleep
    }

    private var sleepColor: Color { BabyEventStyle.accentColor(for: .sleep) }
    private var sleepCardFill: Color { BabyEventStyle.cardFillColor(for: .sleep) }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Label row with pulsing dot
            HStack(spacing: 8) {
                Circle()
                    .fill(sleepColor)
                    .frame(width: 7, height: 7)
                    .symbolEffect(.pulse)

                Text("Sleeping · since \(sleep.startedAt, format: .dateTime.hour().minute())")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(sleepColor)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .accessibilityIdentifier("current-sleep-started-at")
            }

            // Large timer
            TimelineView(.periodic(from: .now, by: 1)) { context in
                timerDisplay(from: sleep.startedAt, to: context.date)
                    .accessibilityIdentifier("current-sleep-duration")
            }

            // Actions
            HStack(spacing: 10) {
                Button(action: stopSleep) {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(sleepColor, in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("current-sleep-stop-button")

                Button(action: logPastSleep) {
                    Text("Log past sleep")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(sleepColor.opacity(0.12), in: Capsule())
                        .overlay(Capsule().stroke(sleepColor.opacity(0.3), lineWidth: 1))
                        .foregroundStyle(sleepColor)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("log-past-sleep-button")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(sleepCardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(sleepColor.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("current-sleep-card")
    }

    @ViewBuilder
    private func timerDisplay(from startedAt: Date, to currentDate: Date) -> some View {
        let seconds = max(0, Int(currentDate.timeIntervalSince(startedAt)))
        let h = seconds / 3_600
        let m = (seconds % 3_600) / 60
        let s = seconds % 60

        HStack(alignment: .firstTextBaseline, spacing: 2) {
            numberPair(value: h, unit: "h")
            numberPair(value: m, unit: "m")
            secondsPair(value: s)
        }
    }

    private func numberPair(value: Int, unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text("\(value)")
                .font(.system(size: 48, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
            Text(unit)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.trailing, 6)
        }
    }

    private func secondsPair(value: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text("\(value)")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.tertiary)
            Text("s")
                .font(.caption.weight(.medium))
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview("Short nap — 45 min") {
    CurrentSleepCardView(
        sleep: CurrentSleepCardViewState(
            sleepEventID: UUID(),
            startedAt: Date(timeIntervalSinceNow: -2_700)
        ),
        stopSleep: {},
        logPastSleep: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Medium sleep — 4h 45m") {
    CurrentSleepCardView(
        sleep: CurrentSleepCardViewState(
            sleepEventID: UUID(),
            startedAt: Date(timeIntervalSinceNow: -17_100)
        ),
        stopSleep: {},
        logPastSleep: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Long overnight — 9h") {
    CurrentSleepCardView(
        sleep: CurrentSleepCardViewState(
            sleepEventID: UUID(),
            startedAt: Date(timeIntervalSinceNow: -32_400)
        ),
        stopSleep: {},
        logPastSleep: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Just started — <1 min") {
    CurrentSleepCardView(
        sleep: CurrentSleepCardViewState(
            sleepEventID: UUID(),
            startedAt: Date(timeIntervalSinceNow: -30)
        ),
        stopSleep: {},
        logPastSleep: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
