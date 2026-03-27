import BabyTrackerDomain
import SwiftUI

public struct EventFilterView: View {
    let currentFilter: EventFilter
    let onApply: (EventFilter) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: EventFilter

    public init(
        currentFilter: EventFilter,
        onApply: @escaping (EventFilter) -> Void
    ) {
        self.currentFilter = currentFilter
        self.onApply = onApply
        self._draft = State(initialValue: currentFilter)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Event Type") {
                    kindToggle("Breast Feed", kind: .breastFeed)
                    kindToggle("Bottle Feed", kind: .bottleFeed)
                    kindToggle("Sleep", kind: .sleep)
                    kindToggle("Nappy", kind: .nappy)
                }

                Section("Nappy Type") {
                    ForEach(NappyType.allCases, id: \.self) { type in
                        nappyTypeToggle(type)
                    }
                }

                Section("Milk Type") {
                    ForEach(MilkType.allCases, id: \.self) { type in
                        milkTypeToggle(type)
                    }
                }

                Section("Breast Side") {
                    ForEach(BreastSide.allCases, id: \.self) { side in
                        breastSideToggle(side)
                    }
                }

                Section("Sleep Duration") {
                    Stepper(
                        draft.sleepMinDurationMinutes.map { "Min: \($0) min" } ?? "Min: any",
                        value: Binding(
                            get: { draft.sleepMinDurationMinutes ?? 0 },
                            set: { draft.sleepMinDurationMinutes = $0 > 0 ? $0 : nil }
                        ),
                        in: 0...720,
                        step: 15
                    )
                    Stepper(
                        draft.sleepMaxDurationMinutes.map { "Max: \($0) min" } ?? "Max: any",
                        value: Binding(
                            get: { draft.sleepMaxDurationMinutes ?? 0 },
                            set: { draft.sleepMaxDurationMinutes = $0 > 0 ? $0 : nil }
                        ),
                        in: 0...720,
                        step: 15
                    )
                }
            }
            .navigationTitle("Filter Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        draft = .empty
                    }
                    .accessibilityIdentifier("event-filter-clear-button")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        onApply(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("event-filter-apply-button")
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Row builders

    private func kindToggle(_ label: String, kind: BabyEventKind) -> some View {
        Toggle(label, isOn: setMemberBinding(value: kind, set: \.eventTypes))
    }

    private func nappyTypeToggle(_ type: NappyType) -> some View {
        Toggle(type.displayName, isOn: setMemberBinding(value: type, set: \.nappyTypes))
    }

    private func milkTypeToggle(_ type: MilkType) -> some View {
        Toggle(type.displayName, isOn: setMemberBinding(value: type, set: \.milkTypes))
    }

    private func breastSideToggle(_ side: BreastSide) -> some View {
        Toggle(side.displayName, isOn: setMemberBinding(value: side, set: \.breastSides))
    }

    /// Returns a `Binding<Bool>` that reflects and toggles membership of `value` in the given set.
    private func setMemberBinding<T: Hashable>(
        value: T,
        set keyPath: WritableKeyPath<EventFilter, Set<T>>
    ) -> Binding<Bool> {
        Binding(
            get: { draft[keyPath: keyPath].contains(value) },
            set: { included in
                var updated = draft
                if included {
                    updated[keyPath: keyPath].insert(value)
                } else {
                    updated[keyPath: keyPath].remove(value)
                }
                draft = updated
            }
        )
    }
}

// MARK: - Display names

private extension NappyType {
    var displayName: String {
        switch self {
        case .dry: "Dry"
        case .wee: "Wee"
        case .poo: "Poo"
        case .mixed: "Mixed"
        }
    }
}

private extension MilkType {
    var displayName: String {
        switch self {
        case .breastMilk: "Breast Milk"
        case .formula: "Formula"
        case .mixed: "Mixed"
        case .other: "Other"
        }
    }
}

private extension BreastSide {
    var displayName: String {
        switch self {
        case .left: "Left"
        case .right: "Right"
        case .both: "Both"
        }
    }
}
