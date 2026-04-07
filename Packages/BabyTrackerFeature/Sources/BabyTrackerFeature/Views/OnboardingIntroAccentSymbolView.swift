import SwiftUI

struct OnboardingIntroAccentSymbolView: View {
    let symbolName: String
    let baseOffset: CGSize
    let floatingOffset: CGSize
    let isFloating: Bool
    let isDrawing: Bool

    var body: some View {
        Image(systemName: symbolName)
            .font(.title3.weight(.semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(Color.accentColor.opacity(0.9))
            .symbolEffect(.drawOn.byLayer, isActive: isDrawing)
            .frame(width: 48, height: 48)
            .background(.ultraThinMaterial, in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
            .scaleEffect(isFloating ? 1 : 0.92)
            .offset(
                x: isFloating ? floatingOffset.width : baseOffset.width,
                y: isFloating ? floatingOffset.height : baseOffset.height
            )
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)

        OnboardingIntroAccentSymbolView(
            symbolName: "moon.zzz.fill",
            baseOffset: CGSize(width: 44, height: -38),
            floatingOffset: CGSize(width: 52, height: -50),
            isFloating: true,
            isDrawing: true
        )
    }
    .frame(width: 200, height: 200)
}
