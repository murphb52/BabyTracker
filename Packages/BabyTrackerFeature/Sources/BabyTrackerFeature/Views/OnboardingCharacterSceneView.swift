import SwiftUI

/// A small looping character vignette that gives each onboarding page a consistent visual anchor.
struct OnboardingCharacterSceneView: View {
    let scene: OnboardingCharacterScene

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(scene.tint.opacity(0.14))
                .overlay(alignment: .topTrailing) {
                    Image(systemName: scene.backgroundSymbolName)
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(scene.tint.opacity(0.18))
                        .padding(18)
                }

            HStack(spacing: 18) {
                character

                VStack(alignment: .leading, spacing: 8) {
                    Label(scene.caption, systemImage: scene.foregroundSymbolName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(scene.tint)
                        .lineLimit(2)

                    Text(scene.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 132)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(scene.accessibilityLabel)
        .onAppear { startAnimation() }
    }

    private var character: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.9))
                .frame(width: 78, height: 78)
                .shadow(color: scene.tint.opacity(0.18), radius: 14, y: 8)

            Circle()
                .fill(scene.tint.opacity(0.95))
                .frame(width: 58, height: 58)
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(.white.opacity(0.28))
                        .frame(width: 18, height: 18)
                        .padding(10)
                }

            HStack(spacing: 9) {
                Circle()
                    .fill(.white)
                    .frame(width: 8, height: 8)
                Circle()
                    .fill(.white)
                    .frame(width: 8, height: 8)
            }
            .offset(y: -5)

            Capsule()
                .fill(.white.opacity(0.9))
                .frame(width: 22, height: 5)
                .offset(y: 13)

            Image(systemName: scene.foregroundSymbolName)
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(scene.tint)
                .padding(11)
                .background(.white, in: Circle())
                .offset(x: 35, y: isAnimating ? -32 : -24)
                .rotationEffect(.degrees(isAnimating ? 9 : -7))
        }
        .offset(y: isAnimating ? -5 : 5)
        .scaleEffect(isAnimating ? 1.02 : 0.98)
        .animation(reduceMotion ? nil : .easeInOut(duration: 1.15).repeatForever(autoreverses: true), value: isAnimating)
    }

    private func startAnimation() {
        guard !reduceMotion else {
            isAnimating = true
            return
        }
        isAnimating = true
    }
}

enum OnboardingCharacterScene: Equatable {
    case tiredMemory
    case quickLog
    case timeline
    case charts
    case sharing
    case privacy
    case liveActivity
    case notifications
    case caregiver
    case babySetup
    case customize
    case firstEvent
    case appPreview

    init(introPageID: String) {
        switch introPageID {
        case "app-help": self = .quickLog
        case "sharing": self = .sharing
        case "security": self = .privacy
        default: self = .tiredMemory
        }
    }

    var caption: String {
        switch self {
        case .tiredMemory: return "A calm place to remember"
        case .quickLog: return "Tiny taps, useful history"
        case .timeline: return "The day comes together"
        case .charts: return "Patterns become clearer"
        case .sharing: return "Caregivers stay in sync"
        case .privacy: return "Private by default"
        case .liveActivity: return "Glanceable updates"
        case .notifications: return "Helpful nudges"
        case .caregiver: return "Your caregiver profile"
        case .babySetup: return "Your baby’s space"
        case .customize: return "Track what matters"
        case .firstEvent: return "Start with one log"
        case .appPreview: return "Ready for real days"
        }
    }

    var detail: String {
        switch self {
        case .tiredMemory: return "Nest keeps the details close when sleep is short."
        case .quickLog: return "Log feeds, nappies, sleep, and more in seconds."
        case .timeline: return "A friendly timeline shows how the day is unfolding."
        case .charts: return "Summaries turn busy days into easy-to-read trends."
        case .sharing: return "Everyone sees the same latest timeline."
        case .privacy: return "Your data stays with you and invited caregivers."
        case .liveActivity: return "See what just happened from the Lock Screen."
        case .notifications: return "Know when something important is logged."
        case .caregiver: return "Add your name so shared logs feel personal."
        case .babySetup: return "Create the profile your logs will belong to."
        case .customize: return "Pick the event buttons that fit your family."
        case .firstEvent: return "Try a real event before entering the app."
        case .appPreview: return "You’re set up and ready to use Nest."
        }
    }

    var tint: Color {
        switch self {
        case .tiredMemory: return .indigo
        case .quickLog: return .mint
        case .timeline: return .blue
        case .charts: return .purple
        case .sharing: return .teal
        case .privacy: return .green
        case .liveActivity: return .orange
        case .notifications: return .pink
        case .caregiver: return .cyan
        case .babySetup: return .accentColor
        case .customize: return .brown
        case .firstEvent: return .yellow
        case .appPreview: return .accentColor
        }
    }

    var foregroundSymbolName: String {
        switch self {
        case .tiredMemory: return "moon.zzz.fill"
        case .quickLog: return "plus.circle.fill"
        case .timeline: return "list.bullet.rectangle.portrait.fill"
        case .charts: return "chart.line.uptrend.xyaxis"
        case .sharing: return "person.2.fill"
        case .privacy: return "lock.shield.fill"
        case .liveActivity: return "iphone.gen3.radiowaves.left.and.right"
        case .notifications: return "bell.badge.fill"
        case .caregiver: return "person.crop.circle.fill"
        case .babySetup: return "teddybear.fill"
        case .customize: return "slider.horizontal.3"
        case .firstEvent: return "sparkles"
        case .appPreview: return "house.fill"
        }
    }

    var backgroundSymbolName: String {
        switch self {
        case .tiredMemory: return "clock.badge.questionmark.fill"
        case .quickLog: return "checkmark.circle.fill"
        case .timeline: return "calendar"
        case .charts: return "chart.bar.xaxis"
        case .sharing: return "arrow.triangle.2.circlepath"
        case .privacy: return "icloud.fill"
        case .liveActivity: return "lock.rectangle.stack.fill"
        case .notifications: return "badge.fill"
        case .caregiver: return "heart.fill"
        case .babySetup: return "star.fill"
        case .customize: return "line.3.horizontal.decrease.circle.fill"
        case .firstEvent: return "hand.tap.fill"
        case .appPreview: return "party.popper.fill"
        }
    }

    var accessibilityLabel: String {
        "Animated onboarding character. \(caption). \(detail)"
    }
}

#Preview("Onboarding Character") {
    VStack(spacing: 16) {
        OnboardingCharacterSceneView(scene: .quickLog)
        OnboardingCharacterSceneView(scene: .charts)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
