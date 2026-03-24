import SwiftUI

struct SleepEditorSheetView: View {
    let mode: Mode
    let saveAction: (_ startedAt: Date, _ endedAt: Date?) -> Bool
    let deleteAction: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var startedAt: Date
    @State private var endedAt: Date

    init(
        mode: Mode,
        initialStartedAt: Date,
        initialEndedAt: Date?,
        saveAction: @escaping (_ startedAt: Date, _ endedAt: Date?) -> Bool,
        deleteAction: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.saveAction = saveAction
        self.deleteAction = deleteAction
        _startedAt = State(initialValue: initialStartedAt)
        _endedAt = State(initialValue: initialEndedAt ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Sleep") {
                    DatePicker(
                        "Start",
                        selection: $startedAt,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .accessibilityIdentifier("sleep-start-time-picker")

                    if mode.showsEndTime {
                        DatePicker(
                            "End",
                            selection: $endedAt,
                            in: ...Date(),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .accessibilityIdentifier("sleep-end-time-picker")
                    }
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    }
                }

                if let deleteAction {
                    Section {
                        Button("Delete Sleep", role: .destructive) {
                            deleteAction()
                            dismiss()
                        }
                        .accessibilityIdentifier("delete-sleep-button")
                    }
                }
            }
            .navigationTitle(mode.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium])
            .onChange(of: startedAt) { _, updatedStart in
                if endedAt < updatedStart {
                    endedAt = updatedStart
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.primaryActionTitle) {
                        let didSave = saveAction(startedAt, mode.showsEndTime ? endedAt : nil)
                        if didSave {
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                    .accessibilityIdentifier("save-sleep-button")
                }
            }
        }
    }

    private var isValid: Bool {
        guard mode.showsEndTime else {
            return true
        }

        return endedAt > startedAt
    }

    private var validationMessage: String? {
        guard mode.showsEndTime, !isValid else {
            return nil
        }

        return "End time must be later than the start time."
    }
}

extension SleepEditorSheetView {
    enum Mode {
        case start
        case end
        case edit

        var navigationTitle: String {
            switch self {
            case .start:
                "Start Sleep"
            case .end:
                "End Sleep"
            case .edit:
                "Edit Sleep"
            }
        }

        var primaryActionTitle: String {
            switch self {
            case .start:
                "Start Sleep"
            case .end:
                "End Sleep"
            case .edit:
                "Update"
            }
        }

        var showsEndTime: Bool {
            switch self {
            case .start:
                false
            case .end, .edit:
                true
            }
        }
    }
}
