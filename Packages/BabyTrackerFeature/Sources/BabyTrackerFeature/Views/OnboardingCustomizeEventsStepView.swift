import SwiftUI

struct OnboardingCustomizeEventsStepView: View {
    let model: AppModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appearedMask = Array(repeating: false, count: 2)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                kindCard
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 8)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear { staggerIn() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What would you like to track?")
                .font(.largeTitle.weight(.bold))
                .opacity(appearedMask[0] ? 1 : 0)
                .offset(y: appearedMask[0] ? 0 : 18)

            Text("Select the events that matter to you. You can change this at any time in Settings.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(appearedMask[1] ? 1 : 0)
                .offset(y: appearedMask[1] ? 0 : 14)
        }
    }

    // MARK: - Kind card

    private var kindCard: some View {
        EventTypeChecklistCardView(
            model: model,
            animateOnAppear: true
        )
    }

    // MARK: - Entrance animation

    private func staggerIn() {
        if reduceMotion {
            appearedMask = Array(repeating: true, count: appearedMask.count)
            return
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(420))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                appearedMask[0] = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.08)) {
                appearedMask[1] = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingCustomizeEventsStepView(
        model: ChildProfilePreviewFactory.makeModel()
    )
    .background(Color(.systemGroupedBackground))
}
