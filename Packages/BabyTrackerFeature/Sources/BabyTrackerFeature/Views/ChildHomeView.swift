import BabyTrackerDomain
import SwiftUI

public struct ChildHomeView: View {
    let model: AppModel
    let viewModel: HomeViewModel
    let childProfileViewModel: ChildProfileViewModel
    let stopSleep: () -> Void
    let logPastSleep: () -> Void
    let quickLogBreastFeed: () -> Void
    let quickLogBottleFeed: () -> Void
    let quickLogSleep: () -> Void
    let quickLogNappy: () -> Void
    let openProfile: () -> Void

    @AppStorage("home.statusSectionExpanded") private var statusSectionExpanded = true
    @AppStorage("home.quickLogSectionExpanded") private var quickLogSectionExpanded = true
    @AppStorage("home.todaySectionExpanded") private var todaySectionExpanded = true
    @AppStorage("home.syncSectionExpanded") private var syncSectionExpanded = true

    public init(
        model: AppModel,
        viewModel: HomeViewModel,
        childProfileViewModel: ChildProfileViewModel,
        stopSleep: @escaping () -> Void,
        logPastSleep: @escaping () -> Void,
        quickLogBreastFeed: @escaping () -> Void,
        quickLogBottleFeed: @escaping () -> Void,
        quickLogSleep: @escaping () -> Void,
        quickLogNappy: @escaping () -> Void,
        openProfile: @escaping () -> Void
    ) {
        self.model = model
        self.viewModel = viewModel
        self.childProfileViewModel = childProfileViewModel
        self.stopSleep = stopSleep
        self.logPastSleep = logPastSleep
        self.quickLogBreastFeed = quickLogBreastFeed
        self.quickLogBottleFeed = quickLogBottleFeed
        self.quickLogSleep = quickLogSleep
        self.quickLogNappy = quickLogNappy
        self.openProfile = openProfile
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HomeGreetingView(childName: viewModel.childName, onAvatarTapped: openProfile)

                heroSentence
                    .padding(.top, -8)

                heroCard
                    .transition(.opacity.combined(with: .move(edge: .top)))

                if viewModel.canLogEvents {
                    quickLogSection
                }

                statusSection

                todaySection

                syncSection
            }
            .animation(.easeInOut(duration: 0.35), value: viewModel.currentSleep)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: statusSectionExpanded)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: quickLogSectionExpanded)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: todaySectionExpanded)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: syncSectionExpanded)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Hero sentence

    @ViewBuilder
    private var heroSentence: some View {
        if let sleepSession = viewModel.activeSleepSession {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                sleepingSentence(startedAt: sleepSession.startedAt, now: context.date)
            }
        } else if let awakeCard = viewModel.awakeHeroCard {
            TimelineView(.everyMinute) { context in
                awakeSentence(awakeStartedAt: awakeCard.awakeStartedAt, now: context.date)
            }
        }
    }

    private func sleepingSentence(startedAt: Date, now: Date) -> some View {
        let name = viewModel.childName ?? "Baby"
        let duration = compactDuration(from: startedAt, to: now)
        let sleepColor = BabyEventStyle.accentColor(for: .sleep)

        return Group {
            if let feedAt = viewModel.heroLastFeedAt {
                let feedTimeText = "Last fed at \(feedAt.formatted(.dateTime.hour().minute()))."
                Text("\(name)'s been asleep \(Text("~\(duration)").fontWeight(.semibold).foregroundStyle(sleepColor)). \(Text(feedTimeText).foregroundStyle(Color.secondary))")
            } else {
                Text("\(name)'s been asleep \(Text("~\(duration)").fontWeight(.semibold).foregroundStyle(sleepColor)).")
            }
        }
        .font(.title2.weight(.medium))
        .foregroundStyle(.primary)
        .lineSpacing(2)
    }

    private func awakeSentence(awakeStartedAt: Date?, now: Date) -> some View {
        let name = viewModel.childName ?? "Baby"
        let durationText: String = awakeStartedAt.map { compactDuration(from: $0, to: now) } ?? "a while"
        let feedKind = viewModel.heroLastFeedKind
        let feedColor: Color = feedKind.map { BabyEventStyle.accentColor(for: $0) } ?? .orange

        return Group {
            if let feedAt = viewModel.heroLastFeedAt {
                let feedLabel = feedKind == .breastFeed ? "breast feed" : "bottle"
                let feedTimeText = "Had a \(feedLabel) at \(feedAt.formatted(.dateTime.hour().minute()))."
                Text("\(name)'s been awake \(Text(durationText).fontWeight(.semibold).foregroundStyle(feedColor)). \(Text(feedTimeText).foregroundStyle(Color.secondary))")
            } else {
                Text("\(name)'s been awake \(Text(durationText).fontWeight(.semibold).foregroundStyle(feedColor)).")
            }
        }
        .font(.title2.weight(.medium))
        .foregroundStyle(.primary)
        .lineSpacing(2)
    }

    /// Produces a compact human-readable duration like "1h 20m" or "45m".
    private func compactDuration(from start: Date, to end: Date) -> String {
        let totalMinutes = max(0, Int(end.timeIntervalSince(start)) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - Hero card

    @ViewBuilder
    private var heroCard: some View {
        if let currentSleep = viewModel.currentSleep {
            CurrentSleepCardView(
                sleep: currentSleep,
                stopSleep: stopSleep,
                logPastSleep: logPastSleep
            )
        } else if let awakeCard = viewModel.awakeHeroCard {
            HomeAwakeHeroCardView(
                card: awakeCard,
                startNap: quickLogSleep,
                logPastSleep: logPastSleep
            )
        }
    }

    // MARK: - Existing sections

    private var syncSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                syncSectionExpanded.toggle()
            } label: {
                HStack {
                    Text("iCloud Sync")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(syncSectionExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if syncSectionExpanded {
                NavigationLink {
                    ChildProfileSyncView(model: model, viewModel: childProfileViewModel)
                } label: {
                    syncStatusCard
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home-sync-status-row")
                .padding(.top, 10)
                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: syncSectionExpanded)
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
        VStack(alignment: .leading, spacing: 0) {
            Button {
                statusSectionExpanded.toggle()
            } label: {
                HStack {
                    Text("Since last")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(statusSectionExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if statusSectionExpanded {
                CurrentStatusCardView(status: viewModel.currentStatus)
                    .padding(.top, 10)
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: statusSectionExpanded)
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                todaySectionExpanded.toggle()
            } label: {
                HStack {
                    Text("Today")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(todaySectionExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if todaySectionExpanded {
                HomeTodayTimelineView(events: viewModel.todayTimelineEvents)
                    .padding(.top, 10)
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: todaySectionExpanded)
    }

    private var quickLogSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                quickLogSectionExpanded.toggle()
            } label: {
                HStack {
                    Text("Quick Log")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(quickLogSectionExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if quickLogSectionExpanded {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
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
                .padding(.top, 12)
                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: quickLogSectionExpanded)
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
        RelativeSyncTextFormatter.lastSyncedText(for: date, relativeTo: referenceDate)
    }
}

// MARK: - Previews

@MainActor
private func makeHomeView(from model: AppModel) -> some View {
    NavigationStack {
        ChildHomeView(
            model: model,
            viewModel: HomeViewModel(appModel: model),
            childProfileViewModel: ChildProfileViewModel(appModel: model),
            stopSleep: {},
            logPastSleep: {},
            quickLogBreastFeed: {},
            quickLogBottleFeed: {},
            quickLogSleep: {},
            quickLogNappy: {},
            openProfile: {}
        )
    }
}

/// Active overnight sleep with a feed and nappy logged earlier in the day.
@MainActor
private func makeSleepingModel() -> AppModel {
    let model = ChildProfilePreviewFactory.makeModel()
    model.logNappy(type: .wee, occurredAt: Date().addingTimeInterval(-6 * 3600), peeVolume: .medium)
    model.logBottleFeed(amountMilliliters: 90, occurredAt: Date().addingTimeInterval(-5 * 3600 - 34 * 60), milkType: .formula)
    model.logBreastFeed(durationMinutes: 10, endTime: Date().addingTimeInterval(-5 * 3600), side: .left)
    model.startSleep(startedAt: Date().addingTimeInterval(-4 * 3600 - 45 * 60))
    return model
}

/// Awake after a completed nap, with a bottle feed logged since waking.
@MainActor
private func makeAwakeWithHistoryModel() -> AppModel {
    let model = ChildProfilePreviewFactory.makeModel()
    model.logNappy(type: .mixed, occurredAt: Date().addingTimeInterval(-3 * 3600), peeVolume: .light, pooVolume: .medium)
    model.logBreastFeed(durationMinutes: 15, endTime: Date().addingTimeInterval(-2 * 3600 - 40 * 60), side: .right)
    model.logSleep(startedAt: Date().addingTimeInterval(-2 * 3600 - 30 * 60), endedAt: Date().addingTimeInterval(-80 * 60))
    model.logBottleFeed(amountMilliliters: 60, occurredAt: Date().addingTimeInterval(-45 * 60), milkType: .breastMilk)
    return model
}

/// Awake a long time — no sleep logged today, only a nappy.
@MainActor
private func makeAwakeLongWindowModel() -> AppModel {
    let model = ChildProfilePreviewFactory.makeModel()
    model.logNappy(type: .poo, occurredAt: Date().addingTimeInterval(-2 * 3600), pooVolume: .medium)
    model.logBottleFeed(amountMilliliters: 120, occurredAt: Date().addingTimeInterval(-3600), milkType: .formula)
    return model
}

#Preview("Sleeping — 4h 45m in") {
    makeHomeView(from: makeSleepingModel())
}

#Preview("Awake after nap — 1h 20m awake") {
    makeHomeView(from: makeAwakeWithHistoryModel())
}

#Preview("Awake — long window, no sleep today") {
    makeHomeView(from: makeAwakeLongWindowModel())
}

#Preview("Fresh — no events logged yet") {
    makeHomeView(from: ChildProfilePreviewFactory.makeModel())
}
