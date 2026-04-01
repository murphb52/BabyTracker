import SwiftUI

/// Shows a deterministic progress bar during a batch event import.
/// Used by both the Huckleberry CSV and Nest JSON import screens.
struct ImportProgressBodyView: View {
    let progress: ImportProgress

    var body: some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(progress.completed), total: Double(progress.total))
                .progressViewStyle(.linear)
                .padding(.horizontal)
            Text("Importing \(progress.completed) of \(progress.total)…")
                .font(.headline)
            Text("Please wait while your events are saved.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ImportProgressBodyView(progress: .init(completed: 120, total: 400))
}
