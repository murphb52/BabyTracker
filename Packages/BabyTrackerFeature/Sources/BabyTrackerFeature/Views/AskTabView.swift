import BabyTrackerDomain
import SwiftUI

/// Connects the Ask screen to the shared `AppModel`. The suggested questions
/// scan every event, so this happens here, where it only runs when the Ask
/// tab itself re-renders, instead of in the parent tab view.
struct AskTabView: View {
    let model: AppModel
    let viewModel: AskViewModel

    var body: some View {
        if let child = model.currentChild {
            AskView(
                viewModel: viewModel,
                child: child,
                suggestedQuestions: AskSuggestedQuestions.make(
                    childName: child.name,
                    loggedKinds: Set(model.events.map(\.kind)).intersection(model.enabledEventKinds)
                )
            )
            .onChange(of: child.id) { _, _ in
                viewModel.startNewConversation()
            }
        }
    }
}

// AskTabView only forwards AppModel state. AppModel needs the full
// persistence and sync stack, so the meaningful previews live on AskView.
