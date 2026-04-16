import BabyTrackerDomain
import SwiftUI

struct LogEventPickerSheetView: View {
    let onSelectKind: (BabyEventKind) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("What would you like to log?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                GlassEffectContainer {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            eventButton(for: .breastFeed)
                            eventButton(for: .bottleFeed)
                        }
                        HStack(spacing: 12) {
                            eventButton(for: .sleep)
                            eventButton(for: .nappy)
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .navigationTitle("Log Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(.regularMaterial)
        .presentationCornerRadius(28)
    }

    private func eventButton(for kind: BabyEventKind) -> some View {
        let accentColor = BabyEventStyle.accentColor(for: kind)

        return Button {
            onSelectKind(kind)
        } label: {
            VStack(spacing: 10) {
                Image(systemName: BabyEventStyle.systemImage(for: kind))
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(accentColor)
                Text(eventTitle(for: kind))
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 110)
        }
        .glassEffect(
            .regular.tint(accentColor.opacity(0.15)).interactive(),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    private func eventTitle(for kind: BabyEventKind) -> String {
        switch kind {
        case .breastFeed: "Breast Feed"
        case .bottleFeed: "Bottle Feed"
        case .sleep: "Sleep"
        case .nappy: "Nappy"
        }
    }
}
