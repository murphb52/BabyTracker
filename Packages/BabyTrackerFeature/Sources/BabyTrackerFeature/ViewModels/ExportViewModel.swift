import BabyTrackerDomain
import Foundation
import Observation

/// Owns the data-export state machine and delegates execution to `AppModel`.
/// Decouples the export UI from `AppModel` so views never reference
/// `AppModel.dataExportState` directly.
@MainActor
@Observable
public final class ExportViewModel {
    public private(set) var state: DataExportState = .idle

    private let appModel: AppModel

    public init(appModel: AppModel) {
        self.appModel = appModel
    }

    public func exportData() {
        guard let child = appModel.profile?.child,
              let membership = appModel.profile?.currentMembership else {
            state = .error("No active child selected")
            return
        }

        state = .exporting

        Task { @MainActor in
            do {
                let url = try appModel.performExport(child: child, membership: membership)
                state = .ready(url)
            } catch {
                state = .error(resolveMessage(for: error))
            }
        }
    }

    public func dismiss() {
        state = .idle
    }

    private func resolveMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }
        return "Something went wrong. Please try again."
    }
}
