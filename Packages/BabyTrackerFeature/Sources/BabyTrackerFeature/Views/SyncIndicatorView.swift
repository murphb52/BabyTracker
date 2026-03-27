import SwiftUI

public struct SyncIndicatorView: View {
    let state: SyncBannerState

    public init(state: SyncBannerState) {
        self.state = state
    }

    public var body: some View {
        HStack(spacing: 8) {
            if state == .syncing {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
            } else {
                Image(systemName: iconName)
                    .font(.caption.weight(.semibold))
            }

            Text(state.message)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(backgroundColor.gradient, in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
        .accessibilityIdentifier("app-sync-indicator")
    }

    private var iconName: String {
        switch state {
        case .syncing:
            "arrow.triangle.2.circlepath"
        case .pendingSync:
            "clock.arrow.circlepath"
        case .syncUnavailable:
            "icloud.slash.fill"
        case .lastSyncFailed:
            "exclamationmark.triangle.fill"
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .syncing:
            .accentColor
        case .pendingSync:
            .indigo
        case .syncUnavailable, .lastSyncFailed:
            .red
        }
    }
}

