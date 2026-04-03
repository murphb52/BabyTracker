import BabyTrackerDomain
import BabyTrackerPersistence
import BabyTrackerSync
import SwiftUI

public struct ChildProfileImportView: View {
    @State private var viewModel: ImportViewModel

    @State private var isFilePickerPresented = false

    public init(appModel: AppModel) {
        _viewModel = State(initialValue: ImportViewModel(appModel: appModel))
    }

    public var body: some View {
        Group {
            switch viewModel.csvImportState {
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
        .navigationTitle("Import Data")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }

    // MARK: - Idle phase

    private var idleView: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Import from Huckleberry")
                        .font(.headline)
                    Text("Choose a CSV file exported from Huckleberry to import your baby's feeding, sleep, and diaper history.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("What gets imported") {
                importableRow(icon: "moon.zzz.fill", title: "Sleep sessions", color: .indigo)
                importableRow(icon: "waterbottle.fill", title: "Bottle feeds (with milk type & amount)", color: .blue)
                importableRow(icon: "figure.seated.side.air.upper", title: "Breast feeds (with side & duration)", color: .pink)
                importableRow(icon: "checklist.checked", title: "Nappy changes (wet, soiled, mixed)", color: .orange)
            }

            Section {
                Button {
                    isFilePickerPresented = true
                } label: {
                    Label("Choose CSV File", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("choose-csv-file-button")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Preview phase

    private func previewView(_ state: ImportPreviewState) -> some View {
        List {
            // Header summary
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
                            "\(state.parseResult.skippedCount) row\(state.parseResult.skippedCount == 1 ? "" : "s") could not be read",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                    }
                }
                .padding(.vertical, 4)
            }

            // Duplicate bulk controls (only shown when duplicates exist)
            if !state.duplicateEvents.isEmpty {
                Section {
                    Button {
                        viewModel.skipAllDuplicates()
                    } label: {
                        Label("Skip all duplicates", systemImage: "xmark.circle")
                    }
                    .accessibilityIdentifier("skip-all-duplicates-button")

                    Button {
                        viewModel.selectAllImportEvents()
                    } label: {
                        Label("Import all including duplicates", systemImage: "arrow.down.circle")
                    }
                    .accessibilityIdentifier("import-all-including-duplicates-button")
                }
            }

            // Event type counts
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

            // New events section
            if !state.newEvents.isEmpty {
                Section("New (\(state.newEvents.count))") {
                    ForEach(state.newEvents) { tagged in
                        ImportEventRow(tagged: tagged, isSelected: true)
                    }
                }
            }

            // Duplicate events section — individually toggleable
            if !state.duplicateEvents.isEmpty {
                Section {
                    ForEach(state.duplicateEvents) { tagged in
                        let isSelected = state.selectedEventIDs.contains(tagged.id)
                        Button {
                            viewModel.toggleImportEvent(id: tagged.id)
                        } label: {
                            ImportEventRow(tagged: tagged, isSelected: isSelected)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("duplicate-event-toggle-\(tagged.id)")
                    }
                } header: {
                    Text("Already imported (\(state.duplicateEvents.count))")
                } footer: {
                    Text("These events exist at the same date and time. Tap to include or exclude individually.")
                        .font(.caption)
                }
            }

            // Skipped parse rows
            if !state.parseResult.skippedReasons.isEmpty {
                Section("Skipped rows") {
                    ForEach(state.parseResult.skippedReasons, id: \.self) { reason in
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Action buttons
            Section {
                let count = state.selectedCount
                Button {
                    viewModel.confirmImport()
                } label: {
                    Label(
                        count == 0 ? "No Events Selected" : "Import \(count) Event\(count == 1 ? "" : "s")",
                        systemImage: "square.and.arrow.down"
                    )
                    .frame(maxWidth: .infinity)
                    .bold()
                }
                .disabled(count == 0)
                .accessibilityIdentifier("confirm-import-button")

                Button(role: .cancel) {
                    viewModel.cancelImport()
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("cancel-import-button")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Importing phase

    private func importingView(_ progress: ImportProgress) -> some View {
        ImportProgressBodyView(progress: progress)
    }

    // MARK: - Complete phase

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
                    viewModel.dismissImportResult()
                } label: {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .accessibilityIdentifier("import-done-button")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Error phase

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
                    viewModel.cancelImport()
                } label: {
                    Text("Try Again")
                        .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("import-retry-button")
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
                viewModel.reportImportFileError("Could not read the selected file")
                return
            }
            viewModel.parseCSVForImport(data: data)
        case .failure(let error):
            viewModel.reportImportFileError(error.localizedDescription)
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

// MARK: - ImportEventRow

private struct ImportEventRow: View {
    let tagged: TaggedImportEvent
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator for duplicates
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

#Preview("Idle") {
    NavigationStack {
        ChildProfileImportView(appModel: ChildProfilePreviewFactory.makeModel())
    }
}

