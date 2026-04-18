import SwiftUI

public struct DriftNotificationDebugView: View {
    let model: AppModel

    @State private var notifications: [PendingDriftNotification] = []
    @State private var isLoading = false
    @State private var now: Date = .now

    public init(model: AppModel) {
        self.model = model
    }

    public var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            } else if notifications.isEmpty {
                ContentUnavailableView(
                    "No Pending Reminders",
                    systemImage: "bell.slash",
                    description: Text("Start a sleep or log an event to schedule drift reminders.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(notifications) { notification in
                    NotificationRow(notification: notification, now: now)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Drift Reminders")
        .navigationBarTitleDisplayMode(.inline)
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
        .task { await load() }
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
        case .sleep: return "Sleep Drift"
        case .inactivity: return "Inactivity"
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
