import SwiftUI

struct HomeGreetingView: View {
    let childName: String?
    let syncBannerState: SyncBannerState?
    let onAvatarTapped: () -> Void

    init(
        childName: String?,
        syncBannerState: SyncBannerState? = nil,
        onAvatarTapped: @escaping () -> Void
    ) {
        self.childName = childName
        self.syncBannerState = syncBannerState
        self.onAvatarTapped = onAvatarTapped
    }

    var body: some View {
        TimelineView(.everyMinute) { context in
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateLabel(for: context.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(greeting(for: context.date))
                        .font(.largeTitle.bold())
                        .foregroundStyle(.primary)
                }

                Spacer(minLength: 0)

                if let syncBannerState {
                    SyncIndicatorView(state: syncBannerState)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                }

                if let initials = childInitials {
                    Button(action: onAvatarTapped) {
                        Text(initials)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.tint)
                            .frame(width: 42, height: 42)
                            .background(.tint.opacity(0.12), in: Circle())
                            .overlay(Circle().stroke(.tint.opacity(0.25), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: syncBannerState)
        }
    }

    private var childInitials: String? {
        guard let name = childName, !name.isEmpty else { return nil }
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return words.prefix(2).compactMap { $0.first.map(String.init) }.joined()
        }
        return String(name.prefix(1))
    }

    private func greeting(for date: Date) -> String {
        let hour = Calendar.autoupdatingCurrent.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    private func dateLabel(for date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }
}

#Preview("Evening with child") {
    HomeGreetingView(childName: "Emily", onAvatarTapped: {})
        .padding()
}

#Preview("Morning with two-word name") {
    HomeGreetingView(childName: "Poppy Rose", onAvatarTapped: {})
        .padding()
}

#Preview("No child yet") {
    HomeGreetingView(childName: nil, onAvatarTapped: {})
        .padding()
}

#Preview("Long name truncation") {
    HomeGreetingView(childName: "Alexandria", onAvatarTapped: {})
        .padding()
}

#Preview("Syncing") {
    HomeGreetingView(childName: nil, syncBannerState: .syncing, onAvatarTapped: {})
        .padding()
}

#Preview("Synced") {
    HomeGreetingView(childName: nil, syncBannerState: .synced, onAvatarTapped: {})
        .padding()
}

#Preview("Sync failed") {
    HomeGreetingView(
        childName: nil,
        syncBannerState: .lastSyncFailed("Sync failed."),
        onAvatarTapped: {}
    )
    .padding()
}
