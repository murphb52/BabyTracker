import SwiftUI
import UIKit

struct HomeAwakeHeroCardView: View {
    let card: HomeAwakeHeroCardViewState
    let startNap: () -> Void
    let logPastSleep: () -> Void

    // Warm amber — distinct from sleep's indigo, reads as awake/daytime energy.
    private var awakeColor: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.98, green: 0.75, blue: 0.30, alpha: 1.0)
                : UIColor(red: 0.80, green: 0.46, blue: 0.06, alpha: 1.0)
        })
    }

    private var awakeCardFill: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.27, green: 0.19, blue: 0.05, alpha: 1.0)
                : UIColor(red: 0.99, green: 0.95, blue: 0.88, alpha: 1.0)
        })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Label row
            HStack(spacing: 8) {
                Circle()
                    .fill(awakeColor)
                    .frame(width: 7, height: 7)

                if let since = card.awakeStartedAt {
                    Text("Awake · since \(since, format: .dateTime.hour().minute())")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(awakeColor)
                        .textCase(.uppercase)
                        .tracking(0.5)
                } else {
                    Text("Awake")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(awakeColor)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
            }

            // Awake window duration — ticks every second like the sleep card
            if let since = card.awakeStartedAt {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    awakeDurationDisplay(from: since, to: context.date)
                }
            } else {
                Text("Awake window")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            // Actions
            HStack(spacing: 10) {
                Button(action: startNap) {
                    Label("Start nap", systemImage: "moon.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(awakeColor, in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                Button(action: logPastSleep) {
                    Text("Log past sleep")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(awakeColor.opacity(0.12), in: Capsule())
                        .overlay(Capsule().stroke(awakeColor.opacity(0.3), lineWidth: 1))
                        .foregroundStyle(awakeColor)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(awakeCardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(awakeColor.opacity(0.3), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func awakeDurationDisplay(from since: Date, to now: Date) -> some View {
        let totalSeconds = max(0, Int(now.timeIntervalSince(since)))
        let h = totalSeconds / 3_600
        let m = (totalSeconds % 3_600) / 60
        let s = totalSeconds % 60

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

#Preview("Just woke — 5 min") {
    HomeAwakeHeroCardView(
        card: HomeAwakeHeroCardViewState(awakeStartedAt: Date(timeIntervalSinceNow: -300)),
        startNap: {},
        logPastSleep: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Normal awake window — 1h 20m") {
    HomeAwakeHeroCardView(
        card: HomeAwakeHeroCardViewState(awakeStartedAt: Date(timeIntervalSinceNow: -4_800)),
        startNap: {},
        logPastSleep: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Long awake — 3h 10m") {
    HomeAwakeHeroCardView(
        card: HomeAwakeHeroCardViewState(awakeStartedAt: Date(timeIntervalSinceNow: -11_400)),
        startNap: {},
        logPastSleep: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("No prior sleep recorded") {
    HomeAwakeHeroCardView(
        card: HomeAwakeHeroCardViewState(awakeStartedAt: nil),
        startNap: {},
        logPastSleep: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
