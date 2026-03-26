import BabyTrackerDomain
import SwiftUI

public struct ChildHomeView: View {
    let profile: ChildProfileScreenState
    let quickLogBreastFeed: () -> Void
    let quickLogBottleFeed: () -> Void
    let quickLogSleep: () -> Void
    let quickLogNappy: () -> Void

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    public init(
        profile: ChildProfileScreenState,
        quickLogBreastFeed: @escaping () -> Void,
        quickLogBottleFeed: @escaping () -> Void,
        quickLogSleep: @escaping () -> Void,
        quickLogNappy: @escaping () -> Void
    ) {
        self.profile = profile
        self.quickLogBreastFeed = quickLogBreastFeed
        self.quickLogBottleFeed = quickLogBottleFeed
        self.quickLogSleep = quickLogSleep
        self.quickLogNappy = quickLogNappy
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                statusSection

                if profile.canLogEvents {
                    quickLogSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current Status")
                .font(.headline)

            CurrentStateCardView(summary: profile.home.currentStateSummary)
        }
    }

    private var quickLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Log")
                .font(.headline)

            LazyVGrid(columns: gridColumns, spacing: 12) {
                quickLogButton(
                    title: "Breast Feed",
                    systemImage: BabyEventStyle.systemImage(for: .breastFeed),
                    tint: BabyEventStyle.accentColor(for: .breastFeed),
                    accessibilityIdentifier: "quick-log-breast-feed-button",
                    action: quickLogBreastFeed
                )

                quickLogButton(
                    title: "Bottle Feed",
                    systemImage: BabyEventStyle.systemImage(for: .bottleFeed),
                    tint: BabyEventStyle.accentColor(for: .bottleFeed),
                    accessibilityIdentifier: "quick-log-bottle-feed-button",
                    action: quickLogBottleFeed
                )

                quickLogButton(
                    title: sleepQuickLogTitle,
                    systemImage: BabyEventStyle.systemImage(for: .sleep),
                    tint: BabyEventStyle.accentColor(for: .sleep),
                    accessibilityIdentifier: "quick-log-sleep-button",
                    action: quickLogSleep
                )

                quickLogButton(
                    title: "Nappy",
                    systemImage: BabyEventStyle.systemImage(for: .nappy),
                    tint: BabyEventStyle.accentColor(for: .nappy),
                    accessibilityIdentifier: "quick-log-nappy-button",
                    action: quickLogNappy
                )
            }
        }
    }

    private func quickLogButton(
        title: String,
        systemImage: String,
        tint: Color,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .padding(.horizontal, 14)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(tint)
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var sleepQuickLogTitle: String {
        profile.activeSleepSession == nil ? "Start Sleep" : "End Sleep"
    }
}
