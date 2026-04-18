import BabyTrackerDomain
import BabyTrackerLiveActivities
import SwiftUI
import UIKit

/// A lock-screen Live Activity demo used on the onboarding flow.
///
/// The device shell is rendered locally in SwiftUI so the feature package stays
/// independent from the widget target while still showing a realistic preview.
struct OnboardingLiveActivityDemoView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var deviceVisible = false
    @State private var activityVisible = false
    @State private var deviceFrameSnapshot: UIImage?

    private let state = FeedLiveActivityAttributes.ContentState(
        childID: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
        childName: "Robyn Murphy",
        lastFeedKind: .breastFeed,
        lastFeedAt: Date.now.addingTimeInterval(-95 * 60),
        lastSleepAt: Date.now.addingTimeInterval(-3 * 60 * 60),
        activeSleepStartedAt: Date.now.addingTimeInterval(-28 * 60),
        lastNappyAt: Date.now.addingTimeInterval(-80 * 60)
    )

    var body: some View {
        GeometryReader { geo in
            let demoViewportHeight = min(geo.size.height, 360.0)
            let deviceWidth = max(220, geo.size.width - 28)
            let deviceHeight = deviceWidth * 2.03

            ZStack(alignment: .bottom) {
                deviceFrameWrapper(width: deviceWidth, height: deviceHeight)

                liveActivityCard
                    .frame(width: deviceWidth - 42)
                    .opacity(activityVisible ? 1 : 0)
                    .padding(.bottom, deviceHeight * 0.12)
                    .offset(y: activityVisible ? 0 : 24)
                    .scaleEffect(activityVisible ? 1 : 0.95, anchor: .bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .frame(height: demoViewportHeight, alignment: .bottom)
            .clipped()
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .black.opacity(0.15), location: 0.10),
                        .init(color: .black.opacity(0.7), location: 0.20),
                        .init(color: .black, location: 0.30),
                        .init(color: .black, location: 1.0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .padding(.bottom, 4)
        }
        .frame(height: 360)
        .onAppear {
            prepareDeviceFrameSnapshot()
            animateIn()
        }
    }

    private func deviceFrameWrapper(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            if let deviceFrameSnapshot {
                Image(uiImage: deviceFrameSnapshot)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: width, height: height)
            } else {
                deviceShell(width: width, height: height)
                    .frame(width: width, height: height)
            }
        }
        .opacity(deviceVisible ? 1 : 0)
        .offset(y: deviceVisible ? 0 : 46)
    }

    private func deviceShell(width: CGFloat, height: CGFloat) -> some View {
        let outerCorner = width * 0.16
        let screenCorner = width * 0.13
        let inset = width * 0.035

        return ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: outerCorner, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.20, green: 0.21, blue: 0.24),
                            Color(red: 0.07, green: 0.07, blue: 0.09),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: outerCorner, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.2), radius: 24, y: 14)

            RoundedRectangle(cornerRadius: screenCorner, style: .continuous)
                .fill(Color.black)
                .overlay {
                    lockScreenBackground
                        .clipShape(RoundedRectangle(cornerRadius: screenCorner, style: .continuous))
                }
                .padding(inset)
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(.black.opacity(0.9))
                        .frame(width: width * 0.34, height: 28)
                        .padding(.top, 18)
                }
                .overlay(alignment: .top) {
                    VStack(spacing: 6) {
                        Text("9:41")
                            .font(.system(size: 40, weight: .thin, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                        Text("Tuesday, April 13")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.top, 66)
                }
        }
        .mask {
            RoundedRectangle(cornerRadius: outerCorner, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .clear, location: 0.12),
                            .init(color: .black.opacity(0.35), location: 0.26),
                            .init(color: .black, location: 0.42),
                            .init(color: .black, location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    private var lockScreenBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.11, blue: 0.25),
                    Color(red: 0.18, green: 0.27, blue: 0.47),
                    Color(red: 0.10, green: 0.15, blue: 0.25),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 210)
                .blur(radius: 12)
                .offset(x: 58, y: -120)

            Circle()
                .fill(Color(red: 0.62, green: 0.78, blue: 1.0).opacity(0.18))
                .frame(width: 180)
                .blur(radius: 18)
                .offset(x: -70, y: -40)
        }
    }

    private var liveActivityCard: some View {
        VStack(alignment: .center, spacing: 12) {
            Text(state.childName)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .foregroundStyle(.white)

            HStack(alignment: .center, spacing: 8) {
                metricTile(
                    title: "Feed",
                    icon: symbolName(for: state.lastFeedKind),
                    color: accentColor(for: .bottleFeed)
                ) {
                    Text(state.lastFeedAt, style: .timer)
                        .liveActivityTimerStyle()
                }

                metricTile(
                    title: state.activeSleepStartedAt == nil ? "Since sleep" : "Asleep",
                    icon: symbolName(for: .sleep),
                    color: accentColor(for: .sleep)
                ) {
                    if let activeSleepStartedAt = state.activeSleepStartedAt {
                        Text(activeSleepStartedAt, style: .timer)
                            .liveActivityTimerStyle()
                    } else if let lastSleepAt = state.lastSleepAt {
                        Text(lastSleepAt, style: .timer)
                            .liveActivityTimerStyle()
                    } else {
                        Text("—")
                    }
                }

                metricTile(
                    title: "Nappy",
                    icon: symbolName(for: .nappy),
                    color: accentColor(for: .nappy)
                ) {
                    if let lastNappyAt = state.lastNappyAt {
                        Text(lastNappyAt, style: .timer)
                            .liveActivityTimerStyle()
                    } else {
                        Text("—")
                    }
                }
            }

            if state.activeSleepStartedAt != nil {
                Label("Stop Sleep", systemImage: "stop.fill")
                    .font(.footnote.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(accentColor(for: .sleep), in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.12, green: 0.15, blue: 0.24))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 16, y: 10)
    }

    private func metricTile(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder value: () -> some View
    ) -> some View {
        VStack(alignment: .center, spacing: 6) {
            HStack(alignment: .center, spacing: 4) {
                Image(systemName: icon)
                    .frame(width: 14)
                Text(title)
            }
            .font(.caption2.weight(.medium))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(color)
            .frame(height: 16)

            value()
                .font(.footnote.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(.white)
                .frame(height: 24, alignment: .center)
        }
        .frame(maxWidth: .infinity)
    }

    private func animateIn() {
        if reduceMotion {
            deviceVisible = true
            activityVisible = true
            return
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(420))
            withAnimation(.spring(response: 0.58, dampingFraction: 0.84)) {
                deviceVisible = true
            }
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.spring(response: 0.52, dampingFraction: 0.82)) {
                activityVisible = true
            }
        }
    }

    @MainActor
    private func prepareDeviceFrameSnapshot() {
        guard deviceFrameSnapshot == nil else { return }

        let width: CGFloat = 320
        let height = width * 2.03
        let renderer = ImageRenderer(
            content: deviceShell(width: width, height: height)
                .frame(width: width, height: height)
        )
        renderer.scale = UIScreen.main.scale
        deviceFrameSnapshot = renderer.uiImage
    }

    private func symbolName(for kind: BabyEventKind) -> String {
        switch kind {
        case .breastFeed:
            "heart.text.square"
        case .bottleFeed:
            "drop.circle"
        case .sleep:
            "bed.double"
        case .nappy:
            "checklist"
        }
    }

    private func accentColor(for kind: BabyEventKind) -> Color {
        switch kind {
        case .breastFeed:
            Color(red: 0.84, green: 0.29, blue: 0.42)
        case .bottleFeed:
            Color(red: 0.15, green: 0.56, blue: 0.72)
        case .sleep:
            Color(red: 0.29, green: 0.33, blue: 0.73)
        case .nappy:
            Color(red: 0.74, green: 0.47, blue: 0.16)
        }
    }
}

#Preview {
    OnboardingLiveActivityDemoView()
        .padding(.horizontal, 24)
}

private extension Text {
    func liveActivityTimerStyle() -> some View {
        HStack(alignment: .center) {
            Spacer()
            Text("00:00:00")
                .hidden()
                .overlay {
                    self
                }
            Spacer()
        }
    }
}
