import BabyTrackerDomain
import SwiftUI

/// A static, non-interactive replica of the Quick Log grid shown on the Home tab.
/// Used as the demo embed on the "Log in seconds" onboarding page.
struct OnboardingQuickLogDemoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Log")
                .font(.headline)
                .padding(.horizontal, 16)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    demoButton("Breast Feed", kind: .breastFeed)
                    demoButton("Bottle Feed", kind: .bottleFeed)
                }

                HStack(spacing: 12) {
                    demoButton("Start Sleep", kind: .sleep)
                    demoButton("Nappy", kind: .nappy)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }

    private func demoButton(_ title: String, kind: BabyEventKind) -> some View {
        Label(title, systemImage: BabyEventStyle.systemImage(for: kind))
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .padding(.horizontal, 14)
            .foregroundStyle(BabyEventStyle.buttonForegroundColor(for: kind))
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(BabyEventStyle.buttonFillColor(for: kind))
            )
    }
}

#Preview {
    OnboardingQuickLogDemoView()
        .frame(width: 320)
}
