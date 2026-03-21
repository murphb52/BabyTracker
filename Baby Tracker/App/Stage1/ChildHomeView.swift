import BabyTrackerFeature
import SwiftUI

struct ChildHomeView: View {
    let profile: ChildProfileScreenState
    let quickLogBreastFeed: () -> Void
    let quickLogBottleFeed: () -> Void
    let quickLogSleep: () -> Void
    let quickLogNappy: () -> Void
    let openEvent: (EventCardViewState) -> Void
    let deleteEvent: (EventCardViewState) -> Void

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                statusSection

                if profile.canLogEvents {
                    quickLogSection
                }

                recentActivitySection
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
                    systemImage: "heart.text.square",
                    tint: .pink,
                    accessibilityIdentifier: "quick-log-breast-feed-button",
                    action: quickLogBreastFeed
                )

                quickLogButton(
                    title: "Bottle Feed",
                    systemImage: "drop.circle",
                    tint: .teal,
                    accessibilityIdentifier: "quick-log-bottle-feed-button",
                    action: quickLogBottleFeed
                )

                quickLogButton(
                    title: sleepQuickLogTitle,
                    systemImage: "bed.double",
                    tint: .indigo,
                    accessibilityIdentifier: "quick-log-sleep-button",
                    action: quickLogSleep
                )

                quickLogButton(
                    title: "Nappy",
                    systemImage: "checklist",
                    tint: .orange,
                    accessibilityIdentifier: "quick-log-nappy-button",
                    action: quickLogNappy
                )
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)

            if profile.home.recentEvents.isEmpty {
                emptyState(
                    title: profile.home.emptyStateTitle,
                    message: profile.home.emptyStateMessage
                )
                .accessibilityIdentifier("home-recent-events-empty-state")
            } else {
                ForEach(profile.home.recentEvents) { event in
                    eventCard(for: event)
                }
            }
        }
    }

    @ViewBuilder
    private func eventCard(for event: EventCardViewState) -> some View {
        if profile.canManageEvents {
            Button {
                openEvent(event)
            } label: {
                EventCardView(event: event)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(primaryActionTitle(for: event)) {
                    openEvent(event)
                }

                Button("Delete", role: .destructive) {
                    deleteEvent(event)
                }
            }
            .accessibilityIdentifier("home-event-\(event.id.uuidString)")
        } else {
            EventCardView(event: event)
                .accessibilityIdentifier("home-event-\(event.id.uuidString)")
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

    private func emptyState(
        title: String,
        message: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var sleepQuickLogTitle: String {
        profile.activeSleepSession == nil ? "Start Sleep" : "End Sleep"
    }

    private func primaryActionTitle(for event: EventCardViewState) -> String {
        switch event.actionPayload {
        case .endSleep:
            "End"
        case .editBreastFeed, .editBottleFeed, .editNappy, .editSleep:
            "Edit"
        }
    }
}
