import SwiftUI

struct OnboardingNotificationPromptView: View {
    let enableAction: () -> Void
    let skipAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 34, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .frame(width: 68, height: 68)
                .background(Color.accentColor.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Enable notifications?")
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("Get a heads-up when another caregiver logs an event so you stay in the loop.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Button("Not Now", action: skipAction)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity)
                
                Button("Enable Notifications", action: enableAction)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
        .frame(maxWidth: 340)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 24, y: 10)
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)

        OnboardingNotificationPromptView(
            enableAction: {},
            skipAction: {}
        )
    }
    .ignoresSafeArea()
}
