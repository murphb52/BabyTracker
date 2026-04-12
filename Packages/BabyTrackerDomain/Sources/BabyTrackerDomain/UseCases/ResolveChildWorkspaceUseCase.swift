import Foundation

/// Decides which child workspace state to enter given the active children list
/// and the user's previously-selected child ID. This is a pure computation —
/// no repositories required.
@MainActor
public struct ResolveChildWorkspaceUseCase: UseCase {
    public struct Input {
        public let activeChildren: [ChildSummary]
        public let selectedChildID: UUID?

        public init(activeChildren: [ChildSummary], selectedChildID: UUID?) {
            self.activeChildren = activeChildren
            self.selectedChildID = selectedChildID
        }
    }

    public enum Resolution: Equatable {
        /// The user has no active children — show the empty state.
        case noActiveChildren
        /// There are multiple children but none matches the stored selection —
        /// the user must pick one explicitly.
        case needsChildSelection
        /// A specific child was resolved. The associated value is the child to
        /// show in the workspace.
        case resolved(ChildSummary)
    }

    public init() {}

    public func execute(_ input: Input) -> Resolution {
        guard !input.activeChildren.isEmpty else {
            return .noActiveChildren
        }

        let selected = input.activeChildren.first(where: { $0.child.id == input.selectedChildID })

        if input.activeChildren.count > 1 && selected == nil {
            return .needsChildSelection
        }

        return .resolved(selected ?? input.activeChildren[0])
    }
}
