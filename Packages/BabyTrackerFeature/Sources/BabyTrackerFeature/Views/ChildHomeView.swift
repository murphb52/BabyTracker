import BabyTrackerDomain
import SwiftUI

public struct ChildHomeView: View {
    let model: AppModel
    let viewModel: HomeViewModel
    let childProfileViewModel: ChildProfileViewModel
    let endBreastFeed: () -> Void
    let stopSleep: () -> Void
    let quickLogBreastFeed: () -> Void
    let quickLogBottleFeed: () -> Void
    let quickLogSleep: () -> Void
    let quickLogNappy: () -> Void


    public init(
        model: AppModel,
        viewModel: HomeViewModel,
        childProfileViewModel: ChildProfileViewModel,
        endBreastFeed: @escaping () -> Void,
        stopSleep: @escaping () -> Void,
        quickLogBreastFeed: @escaping () -> Void,
        quickLogBottleFeed: @escaping () -> Void,
        quickLogSleep: @escaping () -> Void,
        quickLogNappy: @escaping () -> Void
    ) {
        self.model = model
        self.viewModel = viewModel
        self.childProfileViewModel = childProfileViewModel
        self.endBreastFeed = endBreastFeed
        self.stopSleep = stopSleep
        self.quickLogBreastFeed = quickLogBreastFeed
        self.quickLogBottleFeed = quickLogBottleFeed
        self.quickLogSleep = quickLogSleep
        self.quickLogNappy = quickLogNappy
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let activeBreastFeed = viewModel.activeBreastFeedSession {
                    CurrentBreastFeedCardView(
                        session: activeBreastFeed,
                        endBreastFeed: endBreastFeed
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if let currentSleep = viewModel.currentSleep {
                    currentSleepSection(currentSleep)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                statusSection

                if viewModel.canLogEvents {
                    quickLogSection
                }

                syncSection
            }
            .animation(.easeInOut(duration: 0.35), value: viewModel.currentSleep)
            .animation(.easeInOut(duration: 0.35), value: viewModel.activeBreastFeedSession)
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
                ChildProfileSyncView(model: model, viewModel: childProfileViewModel)
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
                    Text(viewModel.syncStatus.statusTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let pendingChangesTitle = viewModel.syncStatus.pendingChangesTitle {
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
        if let lastSyncAt = viewModel.syncStatus.lastSyncAt,
           viewModel.syncStatus.state == .upToDate {
            TimelineView(.everyMinute) { context in
                Text(syncLastUpdatedText(for: lastSyncAt, relativeTo: context.date))
            }
        } else if let detailMessage = viewModel.syncStatus.detailMessage {
            Text(detailMessage)
        } else {
            Text("Open iCloud Sync for more details.")
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current Status")
                .font(.headline)

            CurrentStatusCardView(status: viewModel.currentStatus)
        }
    }

    private var quickLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Log")
                .font(.headline)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    quickLogButton(
                        title: breastFeedQuickLogTitle,
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
                }
                .geometryGroup()

                HStack(spacing: 12) {
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
                .geometryGroup()
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
        viewModel.activeSleepSession == nil ? "Start Sleep" : "End Sleep"
    }

    private var breastFeedQuickLogTitle: String {
        viewModel.activeBreastFeedSession == nil ? "Start Breast Feed" : "End Breast Feed"
    }

    private var syncStatusSymbolName: String {
        if viewModel.syncStatus.isAccountUnavailable {
            return "icloud.slash"
        }

        switch viewModel.syncStatus.state {
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
        switch viewModel.syncStatus.state {
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

#Preview {
    NavigationStack {
        let model = ChildProfilePreviewFactory.makeModel()
        ChildHomeView(
            model: model,
            viewModel: HomeViewModel(appModel: model),
            childProfileViewModel: ChildProfileViewModel(appModel: model),
            endBreastFeed: {},
            stopSleep: {},
            quickLogBreastFeed: {},
            quickLogBottleFeed: {},
            quickLogSleep: {},
            quickLogNappy: {}
        )
    }
}
