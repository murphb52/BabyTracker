import SwiftUI

/// A notification preview scene used in onboarding before requesting permission.
struct OnboardingNotificationsDemoView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @State private var visibleMask = [false, false, false]

    private let notifications: [DemoNotification] = [
        DemoNotification(
            title: "Bottle feed logged",
            message: "Aoife added a 150 mL bottle for Robyn.",
            minutesAgo: 2
        ),
        DemoNotification(
            title: "Sleep started",
            message: "Robyn went down for a nap 8 minutes ago.",
            minutesAgo: 8
        ),
        DemoNotification(
            title: "Nappy changed",
            message: "Dry nappy logged just now.",
            minutesAgo: 0
        ),
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(notifications.enumerated()), id: \.offset) { index, notification in
                notificationCard(notification)
                    .opacity(visibleMask[index] ? 1 : 0)
                    .offset(y: visibleMask[index] ? 0 : 18)
                    .scaleEffect(visibleMask[index] ? 1 : 0.97, anchor: .top)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            animateIn()
        }
    }

    private func notificationCard(_ notification: DemoNotification) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor,
                            Color.accentColor.opacity(0.75),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: "bird.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Nest")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer(minLength: 0)

                    Text(timestampText(for: notification.minutesAgo))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(notification.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(notification.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(notificationCardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(notificationBorderColor, lineWidth: 1)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.24 : 0.08), radius: 14, y: 8)
    }

    private var notificationCardBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.10),
                        Color.white.opacity(0.06),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(.thinMaterial)
        }
    }

    private var notificationBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.7)
    }

    private func timestampText(for minutesAgo: Int) -> String {
        switch minutesAgo {
        case 0:
            return "now"
        case 1:
            return "1m ago"
        default:
            return "\(minutesAgo)m ago"
        }
    }

    private func animateIn() {
        guard !reduceMotion else {
            visibleMask = [true, true, true]
            return
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(420))
            for index in notifications.indices {
                withAnimation(.spring(response: 0.46, dampingFraction: 0.82)) {
                    visibleMask[index] = true
                }
                try? await Task.sleep(for: .milliseconds(180))
            }
        }
    }
}

#Preview {
    OnboardingNotificationsDemoView()
        .padding(.horizontal, 24)
}

private struct DemoNotification {
    let title: String
    let message: String
    let minutesAgo: Int
}
