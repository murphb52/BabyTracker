import BabyTrackerDomain
import SwiftUI

/// The final step of the interactive onboarding flow.
///
/// Shows a personalised welcome with the caregiver's first name and baby's name,
/// a summary card for the event they just logged (with a live timer for active
/// sleep), and a brief "Welcome to Nest" note. Each element animates in one by
/// one after the page slide-in settles.
struct OnboardingAppPreviewStepView: View {
    let model: AppModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appearedMask: [Bool] = [false, false, false, false]

    private var firstName: String {
        let full = model.localUser?.displayName ?? ""
        return full.components(separatedBy: " ").first ?? full
    }

    private var babyName: String {
        model.currentChild?.name ?? "your baby"
    }

    private var latestEvent: BabyEvent? {
        model.events.max(by: { $0.metadata.occurredAt < $1.metadata.occurredAt })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Symbol scene
                AnimatedSymbolSceneView(symbolNames: [
                    "checkmark.seal.fill",
                    "star.fill",
                    "heart.fill",
                ])
                .opacity(appearedMask[0] ? 1 : 0)
                .offset(y: appearedMask[0] ? 0 : 18)

                // Welcome heading
                VStack(alignment: .leading, spacing: 10) {
                    Text("Welcome, \(firstName)!")
                        .font(.largeTitle.weight(.bold))

                    Text("Congratulations on \(babyName).")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(appearedMask[1] ? 1 : 0)
                .offset(y: appearedMask[1] ? 0 : 18)

                // Event summary card
                if let event = latestEvent {
                    eventCard(for: event)
                        .opacity(appearedMask[2] ? 1 : 0)
                        .offset(y: appearedMask[2] ? 0 : 16)
                }

                // Welcome to Nest
                welcomeCard
                    .opacity(appearedMask[3] ? 1 : 0)
                    .offset(y: appearedMask[3] ? 0 : 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 8)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear {
            animateIn()
        }
    }

    // MARK: - Event card

    private func eventCard(for event: BabyEvent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(eventTypeName(for: event) + " logged", systemImage: BabyEventStyle.systemImage(for: event.kind))
                .font(.headline)
                .foregroundStyle(BabyEventStyle.accentColor(for: event.kind))

            eventDetailView(for: event)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private func eventDetailView(for event: BabyEvent) -> some View {
        switch event {
        case let .breastFeed(e):
            Text(breastFeedDetail(e))

        case let .bottleFeed(e):
            Text(bottleFeedDetail(e))

        case let .sleep(e):
            if e.endedAt == nil {
                HStack(spacing: 8) {
                    Circle()
                        .fill(BabyEventStyle.accentColor(for: .sleep))
                        .frame(width: 7, height: 7)
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text("Running · \(sleepDurationText(from: e.startedAt, to: context.date))")
                            .monospacedDigit()
                    }
                }
            } else {
                Text(completedSleepDetail(e))
            }

        case let .nappy(e):
            Text(nappyDetail(e))
        }
    }

    // MARK: - Welcome card

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Welcome to Nest")
                .font(.subheadline.weight(.semibold))
            Text("Your timeline and summary are ready whenever you need them.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Detail formatters

    private func breastFeedDetail(_ e: BreastFeedEvent) -> String {
        let duration = Int(e.endedAt.timeIntervalSince(e.startedAt) / 60)
        let sideLabel: String
        switch e.side {
        case .left:  sideLabel = "Left side"
        case .right: sideLabel = "Right side"
        case .both:  sideLabel = "Both sides"
        case nil:    sideLabel = ""
        }
        return ["\(duration) min", sideLabel].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private func bottleFeedDetail(_ e: BottleFeedEvent) -> String {
        let milkLabel: String
        switch e.milkType {
        case .breastMilk: milkLabel = "Breast milk"
        case .formula:    milkLabel = "Formula"
        case .mixed:      milkLabel = "Mixed"
        case .other:      milkLabel = "Other"
        case nil:         milkLabel = ""
        }
        return ["\(e.amountMilliliters) mL", milkLabel].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private func completedSleepDetail(_ e: SleepEvent) -> String {
        guard let endedAt = e.endedAt else { return "" }
        let duration = Int(endedAt.timeIntervalSince(e.startedAt) / 60)
        return "\(duration) min"
    }

    private func nappyDetail(_ e: NappyEvent) -> String {
        switch e.type {
        case .dry:   return "Dry"
        case .wee:   return "Wee"
        case .poo:   return "Poo"
        case .mixed: return "Mixed"
        }
    }

    private func eventTypeName(for event: BabyEvent) -> String {
        switch event.kind {
        case .breastFeed: return "Breast feed"
        case .bottleFeed: return "Bottle feed"
        case .sleep:      return "Sleep"
        case .nappy:      return "Nappy"
        }
    }

    private func sleepDurationText(from startedAt: Date, to now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(startedAt)))
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let secs = seconds % 60
        return String(format: "%02dh %02dm %02ds", hours, minutes, secs)
    }

    // MARK: - Animation

    private func animateIn() {
        if reduceMotion {
            appearedMask = [true, true, true, true]
            return
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(420))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                appearedMask[0] = true
            }
            try? await Task.sleep(for: .milliseconds(280))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                appearedMask[1] = true
            }
            try? await Task.sleep(for: .milliseconds(320))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                appearedMask[2] = true
            }
            try? await Task.sleep(for: .milliseconds(380))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                appearedMask[3] = true
            }
        }
    }
}

#Preview {
    OnboardingAppPreviewStepView(
        model: ChildProfilePreviewFactory.makeModel()
    )
}
