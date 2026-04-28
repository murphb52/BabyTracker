import BabyTrackerDomain
import SwiftUI

struct OnboardingCustomizeEventsStepView: View {
    let model: AppModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appearedMask: [Bool] = Array(repeating: false, count: 2 + BabyEventKind.allCases.count + 1)

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
        VStack(spacing: 0) {
            ForEach(Array(BabyEventKind.allCases.enumerated()), id: \.element) { index, kind in
                kindRow(kind, appearedIndex: index + 2)

                if kind != BabyEventKind.allCases.last {
                    Divider()
                        .padding(.leading, 60)
                }
            }

            Divider()

            resetRow
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Kind row

    private func kindRow(_ kind: BabyEventKind, appearedIndex: Int) -> some View {
        let isEnabled = model.enabledEventKinds.contains(kind)
        let isOnlyEnabled = isEnabled && model.enabledEventKinds.count == 1

        return Button {
            guard !isOnlyEnabled else { return }
            model.setEventKindEnabled(kind, isEnabled: !isEnabled)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: BabyEventStyle.systemImage(for: kind))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(BabyEventStyle.accentColor(for: kind))
                    .frame(width: 32, height: 32)
                    .background(BabyEventStyle.backgroundColor(for: kind), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(kindTitle(kind))
                        .font(.body)
                        .foregroundStyle(.primary)

                    Text(kindDescription(kind))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isEnabled ? BabyEventStyle.accentColor(for: kind) : Color(.tertiaryLabel))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEnabled)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
            .opacity(isOnlyEnabled ? 0.4 : 1.0)
        }
        .buttonStyle(.plain)
        .opacity(appearedMask[appearedIndex] ? 1 : 0)
        .offset(y: appearedMask[appearedIndex] ? 0 : 14)
    }

    // MARK: - Reset row

    private var resetRow: some View {
        let allEnabled = model.enabledEventKinds.count == BabyEventKind.allCases.count
        let resetIndex = 2 + BabyEventKind.allCases.count

        return Button {
            for kind in BabyEventKind.allCases {
                model.setEventKindEnabled(kind, isEnabled: true)
            }
        } label: {
            Text("Reset to all")
                .font(.subheadline)
                .foregroundStyle(allEnabled ? Color(.tertiaryLabel) : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(allEnabled)
        .opacity(appearedMask[resetIndex] ? 1 : 0)
        .offset(y: appearedMask[resetIndex] ? 0 : 10)
    }

    // MARK: - Copy

    private func kindTitle(_ kind: BabyEventKind) -> String {
        switch kind {
        case .breastFeed: "Breast feed"
        case .bottleFeed: "Bottle feed"
        case .sleep: "Sleep"
        case .nappy: "Nappy"
        }
    }

    private func kindDescription(_ kind: BabyEventKind) -> String {
        switch kind {
        case .breastFeed: "Nursing sessions and duration"
        case .bottleFeed: "Formula and expressed milk"
        case .sleep: "Naps and overnight sleeps"
        case .nappy: "Wet and dirty nappy changes"
        }
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
            for index in 2..<appearedMask.count {
                let delay = Double(index - 2) * 0.08
                withAnimation(.spring(response: 0.42, dampingFraction: 0.78).delay(delay)) {
                    appearedMask[index] = true
                }
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
