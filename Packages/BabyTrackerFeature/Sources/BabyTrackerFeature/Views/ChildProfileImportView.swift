import BabyTrackerDomain
import SwiftUI

public struct ChildProfileImportView: View {
    let model: AppModel

    @State private var isFilePickerPresented = false

    public init(model: AppModel) {
        self.model = model
    }

    public var body: some View {
        Group {
            switch model.csvImportState {
            case .idle:
                idleView
            case .previewing(let result):
                previewView(result)
            case .importing:
                importingView
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
        .onDisappear {
            // Reset to idle if navigating away mid-flow
            if case .error = model.csvImportState { model.cancelImport() }
            if case .idle = model.csvImportState {} else if case .complete = model.csvImportState {} else {
                // Only cancel for non-terminal states when navigating away unexpectedly
            }
        }
    }

    // MARK: - Phase views

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

    private func previewView(_ result: CSVParseResult) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(result.events.count) events ready to import")
                        .font(.headline)
                    if let range = result.dateRange {
                        Text(dateRangeText(range))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if result.skippedCount > 0 {
                        Label(
                            "\(result.skippedCount) row\(result.skippedCount == 1 ? "" : "s") could not be read",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Summary") {
                if result.sleepCount > 0 {
                    eventCountRow(icon: "moon.zzz.fill", label: "Sleep sessions", count: result.sleepCount, color: .indigo)
                }
                if result.bottleFeedCount > 0 {
                    eventCountRow(icon: "waterbottle.fill", label: "Bottle feeds", count: result.bottleFeedCount, color: .blue)
                }
                if result.breastFeedCount > 0 {
                    eventCountRow(icon: "figure.seated.side.air.upper", label: "Breast feeds", count: result.breastFeedCount, color: .pink)
                }
                if result.nappyCount > 0 {
                    eventCountRow(icon: "checklist.checked", label: "Nappy changes", count: result.nappyCount, color: .orange)
                }
            }

            Section("Events") {
                ForEach(result.events) { event in
                    ImportEventRow(event: event)
                }
            }

            if !result.skippedReasons.isEmpty {
                Section("Skipped rows") {
                    ForEach(result.skippedReasons, id: \.self) { reason in
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button {
                    model.confirmImport()
                } label: {
                    Label("Import \(result.events.count) Events", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .disabled(result.events.isEmpty)
                .accessibilityIdentifier("confirm-import-button")

                Button(role: .cancel) {
                    model.cancelImport()
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("cancel-import-button")
            }
        }
        .listStyle(.insetGrouped)
    }

    private var importingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
            Text("Importing events…")
                .font(.headline)
            Text("This won't take long.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

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
                        "\(result.totalSkipped) event\(result.totalSkipped == 1 ? "" : "s") could not be imported",
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
                    model.dismissImportResult()
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
                    model.cancelImport()
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
                model.reportImportFileError("Could not read the selected file")
                return
            }
            model.parseCSVForImport(data: data)
        case .failure(let error):
            model.reportImportFileError(error.localizedDescription)
        }
    }

    // MARK: - Formatting helpers

    private func dateRangeText(_ range: ClosedRange<Date>) -> String {
        let formatter = Date.FormatStyle(date: .abbreviated, time: .omitted)
        let start = range.lowerBound.formatted(formatter)
        let end = range.upperBound.formatted(formatter)
        if start == end {
            return start
        }
        return "\(start) – \(end)"
    }
}

// MARK: - ImportEventRow

private struct ImportEventRow: View {
    let event: ImportableEvent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.displayTitle)
                    .font(.subheadline)
                Text(event.occurredAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var iconName: String {
        switch event {
        case .sleep: return "moon.zzz.fill"
        case .bottleFeed: return "waterbottle.fill"
        case .breastFeed: return "figure.seated.side.air.upper"
        case .nappy: return "checklist.checked"
        }
    }

    private var iconColor: Color {
        switch event {
        case .sleep: return .indigo
        case .bottleFeed: return .blue
        case .breastFeed: return .pink
        case .nappy: return .orange
        }
    }
}
