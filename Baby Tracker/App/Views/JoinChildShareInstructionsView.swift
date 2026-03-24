import SwiftUI

struct JoinChildShareInstructionsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Ask your partner to share their child profile with you through iCloud. Here's how:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    stepRow(number: 1,
                            title: "Open Baby Tracker",
                            detail: "Ask your partner to open the app on their device.")

                    stepRow(number: 2,
                            title: "Go to the Profile tab",
                            detail: "Tap the Profile tab at the bottom of the screen.")

                    stepRow(number: 3,
                            title: "Tap Sharing",
                            detail: "Tap \"Sharing\" to open the sharing settings.")

                    stepRow(number: 4,
                            title: "Invite you as a Caregiver",
                            detail: "Tap \"Invite Caregiver\" and enter your iCloud email address.")

                    stepRow(number: 5,
                            title: "Accept the invitation",
                            detail: "You'll receive an iCloud notification — tap it to accept and the child profile will appear in this app automatically.")

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Color.accentColor)
                            .accessibilityHidden(true)
                        Text("Both you and your partner need to be signed into iCloud on your devices.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.accentColor.opacity(0.08))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .navigationTitle("Get Partner Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("join-share-instructions-done-button")
                }
            }
        }
    }

    @ViewBuilder
    private func stepRow(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(number)")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.accentColor))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
