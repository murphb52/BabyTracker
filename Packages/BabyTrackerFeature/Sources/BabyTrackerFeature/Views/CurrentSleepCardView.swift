import BabyTrackerDomain
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
        HStack(alignment: .center, spacing: 14) {
            sleepIcon

            VStack(alignment: .leading, spacing: 6) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(durationText(from: sleep.startedAt, to: context.date))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(BabyEventStyle.accentColor(for: .sleep))
                        .accessibilityIdentifier("current-sleep-duration")
                }

                Text("Went to sleep \(sleep.startedAt, format: .dateTime.hour().minute())")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("current-sleep-started-at")
            }

            Spacer(minLength: 8)

            Button("Stop") {
                stopSleep()
            }
            .buttonStyle(.borderedProminent)
            .tint(BabyEventStyle.accentColor(for: .sleep))
            .accessibilityIdentifier("current-sleep-stop-button")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BabyEventStyle.backgroundColor(for: .sleep))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(BabyEventStyle.accentColor(for: .sleep).opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("current-sleep-card")
    }

    private var sleepIcon: some View {
        ZStack {
            Circle()
                .fill(BabyEventStyle.backgroundColor(for: .sleep))
                .frame(width: 44, height: 44)

            Image(systemName: BabyEventStyle.systemImage(for: .sleep))
                .font(.title3.weight(.semibold))
                .foregroundStyle(BabyEventStyle.accentColor(for: .sleep))
        }
        .accessibilityHidden(true)
    }

    private func durationText(from startedAt: Date, to currentDate: Date) -> String {
        let seconds = max(0, Int(currentDate.timeIntervalSince(startedAt)))
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let remainingSeconds = seconds % 60

        return String(format: "%02dh %02dm %02ds", hours, minutes, remainingSeconds)
    }
}
