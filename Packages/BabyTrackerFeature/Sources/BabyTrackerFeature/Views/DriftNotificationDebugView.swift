import UIKit
import SwiftUI

public struct DriftNotificationDebugView: View {
    @Environment(\.openURL) private var openURL

    let model: AppModel

    @State private var notifications: [PendingDriftNotification] = []
    @State private var isLoading = false
    @State private var now: Date = .now
    @State private var isShowingPermissionAlert = false

    public init(model: AppModel) {
        self.model = model
    }

    public var body: some View {
        List {
            Section {
                Toggle(
                    "Send Reminder Notifications",
                    isOn: Binding(
                        get: { model.isReminderNotificationsEnabled },
                        set: { isEnabled in
                            Task {
                                let didUpdate = await model.setReminderNotificationsEnabled(isEnabled)
                                await load()
                                if !didUpdate, isEnabled {
                                    isShowingPermissionAlert = true
                                }
                            }
                        }
                    )
                )
                .accessibilityIdentifier("reminder-notifications-toggle")

                Text("We’ll let you know if it’s been a while since you last logged something, so it’s easier to keep your timeline up to date.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            } else if !model.isReminderNotificationsEnabled || notifications.isEmpty {
                ContentUnavailableView(
                    model.isReminderNotificationsEnabled ? "No Pending Reminders" : "Reminder Notifications Off",
                    systemImage: "bell.slash",
                    description: Text(emptyStateDescription)
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(notifications) { notification in
                    NotificationRow(notification: notification, now: now)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Reminder Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Enable Notifications", isPresented: $isShowingPermissionAlert) {
            Button("Open Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(url)
            }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("Turn on notifications in Settings to use reminder notifications.")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await load() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .task {
            await model.refreshReminderNotificationAuthorization()
            await load()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            now = date
        }
    }

    private func load() async {
        isLoading = true
        notifications = await model.fetchPendingDriftNotifications()
        now = .now
        isLoading = false
    }

    private var emptyStateDescription: String {
        if model.isReminderNotificationsEnabled {
            return "Start a sleep or log an event to schedule reminder notifications."
        }

        return "Turn reminder notifications on to schedule future reminders."
    }
}

private struct NotificationRow: View {
    let notification: PendingDriftNotification
    let now: Date

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.kind.symbolName)
                .foregroundStyle(notification.kind.color)
                .imageScale(.large)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(notification.kind.label)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text(countdownText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundStyle(countdownColor)
                }

                Text(notification.childName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(notification.fireDate.formatted(date: .omitted, time: .standard))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    private var secondsRemaining: TimeInterval {
        notification.fireDate.timeIntervalSince(now)
    }

    private var countdownText: String {
        let seconds = max(0, secondsRemaining)
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 {
            return String(format: "%dh %02dm %02ds", h, m, s)
        } else {
            return String(format: "%dm %02ds", m, s)
        }
    }

    private var countdownColor: Color {
        let seconds = secondsRemaining
        if seconds < 60 { return .red }
        if seconds < 300 { return .orange }
        return .primary
    }
}

private extension PendingDriftNotification.Kind {
    var label: String {
        switch self {
        case .sleep: return "Long Sleep Reminder"
        case .inactivity: return "No Activity Reminder"
        }
    }

    var symbolName: String {
        switch self {
        case .sleep: return "moon.zzz.fill"
        case .inactivity: return "clock.badge.exclamationmark.fill"
        }
    }

    var color: Color {
        switch self {
        case .sleep: return .indigo
        case .inactivity: return .orange
        }
    }
}

#Preview {
    NavigationStack {
        DriftNotificationDebugView(model: ChildProfilePreviewFactory.makeModel())
    }
}
