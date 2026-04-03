import BabyTrackerDomain
import Foundation
import Observation

/// Owns the CSV and Nest JSON import state machines and delegates execution
/// to `AppModel`. Decouples import UI from `AppModel` so views never reference
/// `AppModel.csvImportState` or `AppModel.nestImportState` directly.
@MainActor
@Observable
public final class ImportViewModel {
    public private(set) var csvImportState: CSVImportState = .idle
    public private(set) var nestImportState: NestImportState = .idle

    private let appModel: AppModel

    public init(appModel: AppModel) {
        self.appModel = appModel
    }

    // MARK: - CSV Import

    public func parseCSVForImport(data: Data) {
        guard let profile = appModel.profile else {
            csvImportState = .error("No active child selected")
            return
        }

        let parseResult = HuckleberryCSVParser().parse(data: data)

        let taggedEvents: [TaggedImportEvent]
        do {
            taggedEvents = try appModel.checkImportDuplicates(
                events: parseResult.events,
                childID: profile.child.id
            )
        } catch {
            taggedEvents = parseResult.events.map { TaggedImportEvent(event: $0, duplicateStatus: .new) }
        }

        csvImportState = .previewing(ImportPreviewState(parseResult: parseResult, taggedEvents: taggedEvents))
    }

    public func reportImportFileError(_ message: String) {
        csvImportState = .error(message)
    }

    public func toggleImportEvent(id: UUID) {
        guard case .previewing(var previewState) = csvImportState else { return }
        previewState.toggle(id)
        csvImportState = .previewing(previewState)
    }

    public func skipAllDuplicates() {
        guard case .previewing(var previewState) = csvImportState else { return }
        previewState.skipAllDuplicates()
        csvImportState = .previewing(previewState)
    }

    public func selectAllImportEvents() {
        guard case .previewing(var previewState) = csvImportState else { return }
        previewState.selectAllEvents()
        csvImportState = .previewing(previewState)
    }

    public func confirmImport() {
        guard case .previewing(let previewState) = csvImportState else { return }
        guard let profile = appModel.profile, let localUser = appModel.localUser else {
            csvImportState = .error("No active child selected")
            return
        }

        let eventsToImport = previewState.selectedEvents
        guard !eventsToImport.isEmpty else {
            csvImportState = .error("No events selected to import")
            return
        }

        csvImportState = .importing(.init(completed: 0, total: eventsToImport.count))

        Task { @MainActor in
            do {
                let saveResult = try await appModel.performImport(
                    events: eventsToImport,
                    childID: profile.child.id,
                    localUserID: localUser.id,
                    membership: profile.currentMembership,
                    onProgress: { [weak self] completed, total in
                        self?.csvImportState = .importing(.init(completed: completed, total: total))
                    }
                )
                let result = CSVImportResult(
                    importedCount: saveResult.importedCount,
                    skippedParseCount: previewState.parseResult.skippedCount,
                    skippedSaveCount: saveResult.skippedSaveCount,
                    skippedReasons: previewState.parseResult.skippedReasons + saveResult.skippedReasons
                )
                csvImportState = .complete(result)
            } catch {
                csvImportState = .error(resolveMessage(for: error))
            }
        }
    }

    public func cancelImport() {
        csvImportState = .idle
    }

    public func dismissImportResult() {
        csvImportState = .idle
    }

    // MARK: - Nest Import

    public func parseNestFileForImport(data: Data) {
        guard let profile = appModel.profile else {
            nestImportState = .error("No active child selected")
            return
        }

        let parseResult = NestJSONParser().parse(data: data)

        guard !parseResult.events.isEmpty || parseResult.skippedCount > 0 else {
            nestImportState = .error("The selected file contains no recognisable events")
            return
        }

        let taggedEvents: [TaggedImportEvent]
        do {
            taggedEvents = try appModel.checkImportDuplicates(
                events: parseResult.events,
                childID: profile.child.id
            )
        } catch {
            taggedEvents = parseResult.events.map { TaggedImportEvent(event: $0, duplicateStatus: .new) }
        }

        nestImportState = .previewing(ImportPreviewState(parseResult: parseResult, taggedEvents: taggedEvents))
    }

    public func reportNestImportFileError(_ message: String) {
        nestImportState = .error(message)
    }

    public func toggleNestImportEvent(id: UUID) {
        guard case .previewing(var previewState) = nestImportState else { return }
        previewState.toggle(id)
        nestImportState = .previewing(previewState)
    }

    public func skipAllNestDuplicates() {
        guard case .previewing(var previewState) = nestImportState else { return }
        previewState.skipAllDuplicates()
        nestImportState = .previewing(previewState)
    }

    public func selectAllNestImportEvents() {
        guard case .previewing(var previewState) = nestImportState else { return }
        previewState.selectAllEvents()
        nestImportState = .previewing(previewState)
    }

    public func confirmNestImport() {
        guard case .previewing(let previewState) = nestImportState else { return }
        guard let profile = appModel.profile, let localUser = appModel.localUser else {
            nestImportState = .error("No active child selected")
            return
        }

        let eventsToImport = previewState.selectedEvents
        guard !eventsToImport.isEmpty else {
            nestImportState = .error("No events selected to import")
            return
        }

        nestImportState = .importing(.init(completed: 0, total: eventsToImport.count))

        Task { @MainActor in
            do {
                let saveResult = try await appModel.performImport(
                    events: eventsToImport,
                    childID: profile.child.id,
                    localUserID: localUser.id,
                    membership: profile.currentMembership,
                    onProgress: { [weak self] completed, total in
                        self?.nestImportState = .importing(.init(completed: completed, total: total))
                    }
                )
                let result = CSVImportResult(
                    importedCount: saveResult.importedCount,
                    skippedParseCount: previewState.parseResult.skippedCount,
                    skippedSaveCount: saveResult.skippedSaveCount,
                    skippedReasons: previewState.parseResult.skippedReasons + saveResult.skippedReasons
                )
                nestImportState = .complete(result)
            } catch {
                nestImportState = .error(resolveMessage(for: error))
            }
        }
    }

    public func cancelNestImport() {
        nestImportState = .idle
    }

    public func dismissNestImportResult() {
        nestImportState = .idle
    }

    // MARK: - Private

    private func resolveMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }
        return "Something went wrong. Please try again."
    }
}
