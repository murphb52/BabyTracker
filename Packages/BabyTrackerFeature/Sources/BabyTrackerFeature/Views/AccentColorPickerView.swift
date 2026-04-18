import SwiftUI

/// The key used to persist the user's chosen accent colour hex string.
public let accentColorHexKey = "nest.accentColorHex"

/// The default accent colour hex used when no preference has been saved.
public let accentColorHexDefault = "#4A54BA"

struct AccentColorPickerView: View {
    @AppStorage(accentColorHexKey) private var accentColorHex: String = accentColorHexDefault
    @State private var customColor: Color = Color(hex: accentColorHexDefault)

    private let presets: [(name: String, hex: String)] = [
        ("Slate Blue",   "#476699"),
        ("Sleep Indigo", "#4A54BA"),
        ("Cerulean",     "#1F80D6"),
        ("Sage Green",   "#2F856A"),
        ("Forest Green", "#1A7052"),
        ("Warm Violet",  "#8038B3"),
    ]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        List {
            Section("Presets") {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(presets, id: \.hex) { preset in
                        presetSwatch(name: preset.name, hex: preset.hex)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Custom") {
                ColorPicker("Custom colour", selection: $customColor, supportsOpacity: false)
                    .onChange(of: customColor) { _, newColor in
                        accentColorHex = newColor.hexString
                    }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Accent Colour")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            customColor = Color(hex: accentColorHex)
        }
    }

    private func presetSwatch(name: String, hex: String) -> some View {
        let isSelected = accentColorHex.uppercased() == hex.uppercased()
        let color = Color(hex: hex)

        return Button {
            accentColorHex = hex
            customColor = color
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 52, height: 52)
                        .shadow(color: color.opacity(0.45), radius: 8, y: 3)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .overlay {
                    Circle()
                        .strokeBorder(isSelected ? color : Color.clear, lineWidth: 3)
                        .padding(-4)
                }

                Text(name)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? color : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    NavigationStack {
        AccentColorPickerView()
    }
}
