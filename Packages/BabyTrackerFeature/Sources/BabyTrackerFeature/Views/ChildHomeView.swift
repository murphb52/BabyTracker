import BabyTrackerDomain
import SwiftUI

public struct ChildHomeView: View {
    let model: AppModel
    let profile: ChildProfileScreenState
    let stopSleep: () -> Void
    let quickLogBreastFeed: () -> Void
    let quickLogBottleFeed: () -> Void
    let quickLogSleep: () -> Void
    let quickLogNappy: () -> Void

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    public init(
        model: AppModel,
        profile: ChildProfileScreenState,
        stopSleep: @escaping () -> Void,
        quickLogBreastFeed: @escaping () -> Void,
        quickLogBottleFeed: @escaping () -> Void,
        quickLogSleep: @escaping () -> Void,
        quickLogNappy: @escaping () -> Void
    ) {
        self.model = model
        self.profile = profile
        self.stopSleep = stopSleep
        self.quickLogBreastFeed = quickLogBreastFeed
        self.quickLogBottleFeed = quickLogBottleFeed
        self.quickLogSleep = quickLogSleep
        self.quickLogNappy = quickLogNappy
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                if let currentSleep = profile.home.currentSleep {
                    currentSleepSection(currentSleep)
                }

                
                statusSection

                if profile.canLogEvents {
                    quickLogSection
                }
                
                syncSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private func currentSleepSection(_ sleep: CurrentSleepCardViewState) -> some View {
        CurrentSleepCardView(
            sleep: sleep,
            stopSleep: stopSleep
        )
    }

    private var syncSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("iCloud Sync")
                .font(.headline)

            NavigationLink {
                ChildProfileSyncView(model: model, profile: profile)
            } label: {
                syncStatusCard
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home-sync-status-row")
        }
    }

    private var syncStatusCard: some View {
        HStack(spacing: 14) {
            Image(systemName: syncStatusSymbolName)
                .font(.headline)
                .foregroundStyle(syncStatusColor)
                .frame(width: 24, height: 24)
                .background(syncStatusColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(profile.home.syncStatus.statusTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let pendingChangesTitle = profile.home.syncStatus.pendingChangesTitle {
                        Text(pendingChangesTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(syncStatusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(syncStatusColor.opacity(0.12), in: Capsule())
                    }
                }

                syncStatusDetail
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var syncStatusDetail: some View {
        if let lastSyncAt = profile.home.syncStatus.lastSyncAt,
           profile.home.syncStatus.state == .upToDate {
            TimelineView(.everyMinute) { context in
                Text(syncLastUpdatedText(for: lastSyncAt, relativeTo: context.date))
            }
        } else if let detailMessage = profile.home.syncStatus.detailMessage {
            Text(detailMessage)
        } else {
            Text("Open iCloud Sync for more details.")
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current Status")
                .font(.headline)

            CurrentStatusCardView(status: profile.home.currentStatus)
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
                    kind: .breastFeed,
                    accessibilityIdentifier: "quick-log-breast-feed-button",
                    action: quickLogBreastFeed
                )

                quickLogButton(
                    title: "Bottle Feed",
                    systemImage: BabyEventStyle.systemImage(for: .bottleFeed),
                    kind: .bottleFeed,
                    accessibilityIdentifier: "quick-log-bottle-feed-button",
                    action: quickLogBottleFeed
                )

                quickLogButton(
                    title: sleepQuickLogTitle,
                    systemImage: BabyEventStyle.systemImage(for: .sleep),
                    kind: .sleep,
                    accessibilityIdentifier: "quick-log-sleep-button",
                    action: quickLogSleep
                )

                quickLogButton(
                    title: "Nappy",
                    systemImage: BabyEventStyle.systemImage(for: .nappy),
                    kind: .nappy,
                    accessibilityIdentifier: "quick-log-nappy-button",
                    action: quickLogNappy
                )
            }
        }
    }

    private func quickLogButton(
        title: String,
        systemImage: String,
        kind: BabyEventKind,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .padding(.horizontal, 14)
                .foregroundStyle(BabyEventStyle.buttonForegroundColor(for: kind))
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(BabyEventStyle.buttonFillColor(for: kind))
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var sleepQuickLogTitle: String {
        profile.activeSleepSession == nil ? "Start Sleep" : "End Sleep"
    }

    private var syncStatusSymbolName: String {
        if profile.home.syncStatus.isAccountUnavailable {
            return "icloud.slash"
        }

        switch profile.home.syncStatus.state {
        case .upToDate:
            return "checkmark.circle.fill"
        case .pendingSync:
            return "clock.arrow.circlepath"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .failed:
            return "xmark.circle.fill"
        }
    }

    private var syncStatusColor: Color {
        if profile.home.syncStatus.isAccountUnavailable {
            return .orange
        }

        switch profile.home.syncStatus.state {
        case .upToDate:
            return .green
        case .pendingSync:
            return .orange
        case .syncing:
            return .accentColor
        case .failed:
            return .red
        }
    }

    private func syncLastUpdatedText(
        for date: Date,
        relativeTo referenceDate: Date
    ) -> String {
        let formatter = RelativeDateTimeFormatter()
        return "Last synced \(formatter.localizedString(for: date, relativeTo: referenceDate))"
    }
}

#Preview("Synced") {
    NavigationStack {
        let model = ChildProfilePreviewFactory.makeModel()
        if let profile = model.profile {
            ChildHomeView(
                model: model,
                profile: previewProfile(
                    from: profile,
                    syncSummary: SyncStatusSummary(
                        state: .upToDate,
                        pendingRecordCount: 0,
                        lastSyncAt: .now.addingTimeInterval(-600)
                    )
                ),
                stopSleep: {},
                quickLogBreastFeed: {},
                quickLogBottleFeed: {},
                quickLogSleep: {},
                quickLogNappy: {}
            )
        }
    }
}

#Preview("Waiting To Sync") {
    NavigationStack {
        let model = ChildProfilePreviewFactory.makeModel()
        if let profile = model.profile {
            ChildHomeView(
                model: model,
                profile: previewProfile(
                    from: profile,
                    syncSummary: SyncStatusSummary(
                        state: .pendingSync,
                        pendingRecordCount: 3,
                        lastSyncAt: nil
                    )
                ),
                stopSleep: {},
                quickLogBreastFeed: {},
                quickLogBottleFeed: {},
                quickLogSleep: {},
                quickLogNappy: {}
            )
        }
    }
}

#Preview("Unavailable") {
    NavigationStack {
        let model = ChildProfilePreviewFactory.makeModel()
        if let profile = model.profile {
            ChildHomeView(
                model: model,
                profile: previewProfile(
                    from: profile,
                    syncSummary: SyncStatusSummary(
                        state: .failed,
                        pendingRecordCount: 0,
                        lastSyncAt: nil,
                        lastErrorDescription: "Sync unavailable. Sign in to iCloud."
                    )
                ),
                stopSleep: {},
                quickLogBreastFeed: {},
                quickLogBottleFeed: {},
                quickLogSleep: {},
                quickLogNappy: {}
            )
        }
    }
}

private func previewProfile(
    from profile: ChildProfileScreenState,
    syncSummary: SyncStatusSummary
) -> ChildProfileScreenState {
    let syncStatus = CloudKitStatusViewState(summary: syncSummary)

    return ChildProfileScreenState(
        child: profile.child,
        localUser: profile.localUser,
        currentMembership: profile.currentMembership,
        owner: profile.owner,
        activeCaregivers: profile.activeCaregivers,
        pendingShareInvites: profile.pendingShareInvites,
        removedCaregivers: profile.removedCaregivers,
        canLogEvents: profile.canLogEvents,
        canManageEvents: profile.canManageEvents,
        activeSleepSession: profile.activeSleepSession,
        home: HomeScreenState(
            currentSleep: profile.home.currentSleep,
            currentStatus: profile.home.currentStatus,
            syncStatus: syncStatus,
            recentEvents: profile.home.recentEvents,
            emptyStateTitle: profile.home.emptyStateTitle,
            emptyStateMessage: profile.home.emptyStateMessage
        ),
        eventHistory: profile.eventHistory,
        timeline: profile.timeline,
        summary: profile.summary,
        cloudKitStatus: syncStatus,
        latestEventSyncMarker: profile.latestEventSyncMarker,
        totalEventCount: profile.totalEventCount,
        canShareChild: profile.canShareChild,
        pendingChanges: profile.pendingChanges,
        availableChildren: profile.availableChildren,
        canCreateLocalChild: profile.canCreateLocalChild
    )
}
