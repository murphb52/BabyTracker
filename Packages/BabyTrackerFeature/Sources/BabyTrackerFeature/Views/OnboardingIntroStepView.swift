import SwiftUI

struct OnboardingIntroStepView: View {
    let page: OnboardingIntroPage

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)

            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.accentColor.opacity(0.14))
                    .frame(width: 112, height: 112)

                Image(systemName: page.symbolName)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 12) {
                Text(page.title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)

                Text(page.message)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 24)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.thinMaterial)
                .overlay {
                    HStack(spacing: 16) {
                        featureBadge(title: "Fast logging", symbolName: "checkmark.circle.fill")
                        featureBadge(title: "Shared timeline", symbolName: "person.2.fill")
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 84)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func featureBadge(title: String, symbolName: String) -> some View {
        Label(title, systemImage: symbolName)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    OnboardingIntroStepView(
        page: OnboardingIntroPage(
            title: "Track every feed, sleep, and nappy",
            message: "Log the moments that matter without digging through a complicated setup.",
            symbolName: "drop.circle.fill"
        )
    )
}
