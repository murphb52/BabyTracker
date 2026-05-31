import BabyTrackerDomain
import SwiftUI

struct EventTypeChecklistCardView: View {
    let model: AppModel
    let animateOnAppear: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appearedMask = Array(repeating: false, count: BabyEventKind.allCases.count + 1)

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(BabyEventKind.allCases.enumerated()), id: \.element) { index, kind in
                kindRow(kind, appearedIndex: index)

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
        .onAppear {
            guard animateOnAppear else {
                appearedMask = Array(repeating: true, count: appearedMask.count)
                return
            }
            staggerIn()
        }
    }

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
                    .background(
                        BabyEventStyle.backgroundColor(for: kind),
                        in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title(for: kind))
                        .font(.body)
                        .foregroundStyle(.primary)

                    Text(description(for: kind))
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
        .accessibilityIdentifier("event-visibility-toggle-\(kind.rawValue)")
        .opacity(appearedMask[appearedIndex] ? 1 : 0)
        .offset(y: appearedMask[appearedIndex] ? 0 : 14)
    }

    private var resetRow: some View {
        let allEnabled = model.enabledEventKinds.count == BabyEventKind.allCases.count
        let resetIndex = BabyEventKind.allCases.count

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
        .accessibilityIdentifier("event-visibility-reset-button")
        .opacity(appearedMask[resetIndex] ? 1 : 0)
        .offset(y: appearedMask[resetIndex] ? 0 : 10)
    }

    private func title(for kind: BabyEventKind) -> String {
        switch kind {
        case .bath: "Bath"
        case .breastFeed: "Breast feed"
        case .bottleFeed: "Bottle feed"
        case .sleep: "Sleep"
        case .nappy: "Nappy"
        case .medication: "Medication"
        }
    }

    private func description(for kind: BabyEventKind) -> String {
        switch kind {
        case .bath: "Baths with shampoo and soap details"
        case .breastFeed: "Nursing sessions and duration"
        case .bottleFeed: "Formula and expressed milk"
        case .sleep: "Naps and overnight sleeps"
        case .nappy: "Wet and dirty nappy changes"
        case .medication: "Doses, amounts and units"
        }
    }

    private func staggerIn() {
        if reduceMotion {
            appearedMask = Array(repeating: true, count: appearedMask.count)
            return
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(420))
            for index in appearedMask.indices {
                let delay = Double(index) * 0.08
                withAnimation(.spring(response: 0.42, dampingFraction: 0.78).delay(delay)) {
                    appearedMask[index] = true
                }
            }
        }
    }
}

#Preview("Static") {
    EventTypeChecklistCardView(
        model: ChildProfilePreviewFactory.makeModel(),
        animateOnAppear: false
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Animated") {
    EventTypeChecklistCardView(
        model: ChildProfilePreviewFactory.makeModel(),
        animateOnAppear: true
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
