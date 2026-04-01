import BabyTrackerDomain
import BabyTrackerPersistence
import BabyTrackerSync
import SwiftUI
import UniformTypeIdentifiers

public struct ChildProfileNestImportView: View {
    let model: AppModel

    @State private var isFilePickerPresented = false

    public init(model: AppModel) {
        self.model = model
    }

    public var body: some View {
        Group {
            switch model.nestImportState {
            case .idle:
                idleView
            case .previewing(let previewState):
                previewView(previewState)
            case .importing(let progress):
                importingView(progress)
            case .complete(let result):
                completeView(result)
            case .error(let message):
                errorView(message)
            }
        }
        .navigationTitle("Import from Nest")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Import from Nest")
                        .font(.headline)
                    Text("Choose a JSON file previously exported from Nest to restore your baby's logged events.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("What gets imported") {
                importableRow(icon: "moon.zzz.fill", title: "Sleep sessions", color: .indigo)
                importableRow(icon: "waterbottle.fill", title: "Bottle feeds (amount & milk type)", color: .blue)
                importableRow(icon: "figure.seated.side.air.upper", title: "Breast feeds (side & duration)", color: .pink)
                importableRow(icon: "checklist.checked", title: "Nappy changes (type, volume & colour)", color: .orange)
            }

            Section {
                Button {
                    isFilePickerPresented = true
                } label: {
                    Label("Choose JSON File", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("choose-nest-json-file-button")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Preview

    private func previewView(_ state: ImportPreviewState) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    if state.duplicateEvents.isEmpty {
                        Text("\(state.taggedEvents.count) events ready to import")
                            .font(.headline)
                    } else {
                        Text("\(state.taggedEvents.count) events found")
                            .font(.headline)
                        Text("\(state.newEvents.count) new · \(state.duplicateEvents.count) already imported")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let range = state.parseResult.dateRange {
                        Text(dateRangeText(range))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if state.parseResult.skippedCount > 0 {
                        Label(
                            "\(state.parseResult.skippedCount) event\(state.parseResult.skippedCount == 1 ? "" : "s") could not be read",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                    }
                }
                .padding(.vertical, 4)
            }

            if !state.duplicateEvents.isEmpty {
                Section {
                    Button {
                        model.skipAllNestDuplicates()
                    } label: {
                        Label("Skip all duplicates", systemImage: "xmark.circle")
                    }
                    .accessibilityIdentifier("nest-skip-all-duplicates-button")

                    Button {
                        model.selectAllNestImportEvents()
                    } label: {
                        Label("Import all including duplicates", systemImage: "arrow.down.circle")
                    }
                    .accessibilityIdentifier("nest-import-all-including-duplicates-button")
                }
            }

            Section("Summary") {
                let sleepCount = state.taggedEvents.filter { if case .sleep = $0.event { true } else { false } }.count
                let bottleCount = state.taggedEvents.filter { if case .bottleFeed = $0.event { true } else { false } }.count
                let breastCount = state.taggedEvents.filter { if case .breastFeed = $0.event { true } else { false } }.count
                let nappyCount = state.taggedEvents.filter { if case .nappy = $0.event { true } else { false } }.count

                if sleepCount > 0 {
                    eventCountRow(icon: "moon.zzz.fill", label: "Sleep sessions", count: sleepCount, color: .indigo)
                }
                if bottleCount > 0 {
                    eventCountRow(icon: "waterbottle.fill", label: "Bottle feeds", count: bottleCount, color: .blue)
                }
                if breastCount > 0 {
                    eventCountRow(icon: "figure.seated.side.air.upper", label: "Breast feeds", count: breastCount, color: .pink)
                }
                if nappyCount > 0 {
                    eventCountRow(icon: "checklist.checked", label: "Nappy changes", count: nappyCount, color: .orange)
                }
            }

            if !state.newEvents.isEmpty {
                Section("New (\(state.newEvents.count))") {
                    ForEach(state.newEvents) { tagged in
                        NestImportEventRow(tagged: tagged, isSelected: true)
                    }
                }
            }

            if !state.duplicateEvents.isEmpty {
                Section {
                    ForEach(state.duplicateEvents) { tagged in
                        let isSelected = state.selectedEventIDs.contains(tagged.id)
                        Button {
                            model.toggleNestImportEvent(id: tagged.id)
                        } label: {
                            NestImportEventRow(tagged: tagged, isSelected: isSelected)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("nest-duplicate-event-toggle-\(tagged.id)")
                    }
                } header: {
                    Text("Already imported (\(state.duplicateEvents.count))")
                } footer: {
                    Text("These events exist at the same date and time. Tap to include or exclude individually.")
                        .font(.caption)
                }
            }

            if !state.parseResult.skippedReasons.isEmpty {
                Section("Skipped events") {
                    ForEach(state.parseResult.skippedReasons, id: \.self) { reason in
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                let count = state.selectedCount
                Button {
                    model.confirmNestImport()
                } label: {
                    Label(
                        count == 0 ? "No Events Selected" : "Import \(count) Event\(count == 1 ? "" : "s")",
                        systemImage: "square.and.arrow.down"
                    )
                    .frame(maxWidth: .infinity)
                    .bold()
                }
                .disabled(count == 0)
                .accessibilityIdentifier("nest-confirm-import-button")

                Button(role: .cancel) {
                    model.cancelNestImport()
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("nest-cancel-import-button")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Importing

    private func importingView(_ progress: ImportProgress) -> some View {
        ImportProgressBodyView(progress: progress)
    }

    // MARK: - Complete

    private func completeView(_ result: CSVImportResult) -> some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text("Import Complete")
                        .font(.title2)
                        .bold()

                    Text("\(result.importedCount) event\(result.importedCount == 1 ? "" : "s") imported successfully")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            if result.totalSkipped > 0 {
                Section {
                    Label(
                        "\(result.totalSkipped) event\(result.totalSkipped == 1 ? "" : "s") skipped",
                        systemImage: "exclamationmark.triangle"
                    )
                    .foregroundStyle(.orange)

                    ForEach(result.skippedReasons, id: \.self) { reason in
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button {
                    model.dismissNestImportResult()
                } label: {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .accessibilityIdentifier("nest-import-done-button")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.red)

                    Text("Import Failed")
                        .font(.title2)
                        .bold()

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section {
                Button {
                    model.cancelNestImport()
                } label: {
                    Text("Try Again")
                        .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("nest-import-retry-button")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Row helpers

    private func importableRow(icon: String, title: String, color: Color) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(color)
        }
    }

    private func eventCountRow(icon: String, label: String, count: Int, color: Color) -> some View {
        LabeledContent {
            Text("\(count)")
                .foregroundStyle(.secondary)
        } label: {
            Label {
                Text(label)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(color)
            }
        }
    }

    // MARK: - File handling

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else {
                model.reportNestImportFileError("Could not read the selected file")
                return
            }
            model.parseNestFileForImport(data: data)
        case .failure(let error):
            model.reportNestImportFileError(error.localizedDescription)
        }
    }

    // MARK: - Formatting helpers

    private func dateRangeText(_ range: ClosedRange<Date>) -> String {
        let formatter = Date.FormatStyle(date: .abbreviated, time: .omitted)
        let start = range.lowerBound.formatted(formatter)
        let end = range.upperBound.formatted(formatter)
        if start == end { return start }
        return "\(start) – \(end)"
    }
}

// MARK: - Preview

#Preview("Idle") {
    NavigationStack {
        ChildProfileNestImportView(model: ChildProfilePreviewFactory.makeModel())
    }
}

// MARK: - NestImportEventRow

private struct NestImportEventRow: View {
    let tagged: TaggedImportEvent
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            if tagged.isDuplicate {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .font(.title3)
            }

            Image(systemName: iconName)
                .foregroundStyle(iconColor.opacity(tagged.isDuplicate && !isSelected ? 0.4 : 1))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(tagged.event.displayTitle)
                        .font(.subheadline)
                        .foregroundStyle(tagged.isDuplicate && !isSelected ? .secondary : .primary)

                    if tagged.isDuplicate {
                        Text("duplicate")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(isSelected ? Color.orange : Color.secondary, in: Capsule())
                    }
                }
                Text(tagged.event.occurredAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var iconName: String {
        switch tagged.event {
        case .sleep: return "moon.zzz.fill"
        case .bottleFeed: return "waterbottle.fill"
        case .breastFeed: return "figure.seated.side.air.upper"
        case .nappy: return "checklist.checked"
        }
    }

    private var iconColor: Color {
        switch tagged.event {
        case .sleep: return .indigo
        case .bottleFeed: return .blue
        case .breastFeed: return .pink
        case .nappy: return .orange
        }
    }
}
