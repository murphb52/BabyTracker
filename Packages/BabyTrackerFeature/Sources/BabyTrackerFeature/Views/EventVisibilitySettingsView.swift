import BabyTrackerDomain
import SwiftUI

public struct EventVisibilitySettingsView: View {
    let model: AppModel

    public init(model: AppModel) {
        self.model = model
    }

    public var body: some View {
        List {
            Section {
                ForEach(BabyEventKind.allCases, id: \.self) { kind in
                    eventToggleRow(for: kind)
                }
            } footer: {
                Text("Disabled events stay hidden across the app, but your existing data is never deleted. Re-enable an event at any time to see it again.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Customize Events")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func eventToggleRow(for kind: BabyEventKind) -> some View {
        let isEnabled = model.isEventKindEnabled(kind)
        let isOnlyEnabled = isEnabled && model.enabledEventKinds.count == 1

        return Toggle(isOn: Binding(
            get: { model.isEventKindEnabled(kind) },
            set: { model.setEventKindEnabled(kind, isEnabled: $0) }
        )) {
            HStack(spacing: 12) {
                Image(systemName: BabyEventStyle.systemImage(for: kind))
                    .foregroundStyle(BabyEventStyle.accentColor(for: kind))
                    .frame(width: 24)
                Text(BabyEventPresentation.title(for: kind))
            }
        }
        .disabled(isOnlyEnabled)
        .accessibilityIdentifier("event-visibility-toggle-\(kind.rawValue)")
    }
}

#Preview {
    NavigationStack {
        EventVisibilitySettingsView(model: ChildProfilePreviewFactory.makeModel())
    }
}
