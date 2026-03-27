import SwiftUI

public struct QuickTimeSelectorView: View {
    @Binding var selection: Date

    @State private var selectedPreset: TimePreset
    @State private var showCustomPicker: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    public init(selection: Binding<Date>, initialPreset: TimePreset = .now) {
        _selection = selection
        _selectedPreset = State(initialValue: initialPreset)
        _showCustomPicker = State(initialValue: initialPreset == .custom)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(TimePreset.allCases) { preset in
                    Button {
                        selectedPreset = preset
                        if preset == .custom {
                            showCustomPicker = true
                        } else {
                            showCustomPicker = false
                            selection = preset.date()
                        }
                    } label: {
                        Text(preset.label)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(selectedPreset == preset ? Color.accentColor : Color(.tertiarySystemGroupedBackground))
                            )
                            .foregroundStyle(selectedPreset == preset ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("time-preset-\(preset.rawValue)")
                }
            }
            if showCustomPicker {
                DatePicker(
                    "Custom time",
                    selection: $selection,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .accessibilityIdentifier("time-preset-custom-picker")
            }
        }
    }
}

extension QuickTimeSelectorView {
    public enum TimePreset: String, CaseIterable, Identifiable {
        case now
        case fiveMinutesAgo = "5m"
        case tenMinutesAgo = "10m"
        case fifteenMinutesAgo = "15m"
        case twentyMinutesAgo = "20m"
        case thirtyMinutesAgo = "30m"
        case custom

        public var id: String { rawValue }

        public var label: String {
            switch self {
            case .now: return "Now"
            case .fiveMinutesAgo: return "5m ago"
            case .tenMinutesAgo: return "10m ago"
            case .fifteenMinutesAgo: return "15m ago"
            case .twentyMinutesAgo: return "20m ago"
            case .thirtyMinutesAgo: return "30m ago"
            case .custom: return "Custom"
            }
        }

        public func date() -> Date {
            switch self {
            case .now: return Date()
            case .fiveMinutesAgo: return Date().addingTimeInterval(-5 * 60)
            case .tenMinutesAgo: return Date().addingTimeInterval(-10 * 60)
            case .fifteenMinutesAgo: return Date().addingTimeInterval(-15 * 60)
            case .twentyMinutesAgo: return Date().addingTimeInterval(-20 * 60)
            case .thirtyMinutesAgo: return Date().addingTimeInterval(-30 * 60)
            case .custom: return Date()
            }
        }
    }
}

#Preview {
    Form {
        Section("Time") {
            QuickTimeSelectorView(selection: .constant(Date()))
        }
    }
}
