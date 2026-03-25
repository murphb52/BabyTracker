import BabyTrackerDomain
import SwiftUI
import UIKit

public struct LoggingView: View {
    let appLogger: AppLogger

    @State private var searchText = ""
    @State private var selectedLevel: LogLevel?

    public init(appLogger: AppLogger) {
        self.appLogger = appLogger
    }

    public var body: some View {
        List(filteredEntries) { entry in
            LogEntryRow(entry: entry)
        }
        .listStyle(.plain)
        .navigationTitle("Logs")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search logs")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                levelFilterMenu
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                actionsMenu
            }
        }
        .overlay {
            if appLogger.entries.isEmpty {
                ContentUnavailableView(
                    "No Logs",
                    systemImage: "text.justify.left",
                    description: Text("Logs will appear here as the app runs.")
                )
            } else if filteredEntries.isEmpty {
                ContentUnavailableView.search
            }
        }
    }

    private var levelFilterMenu: some View {
        Menu {
            Button {
                selectedLevel = nil
            } label: {
                HStack {
                    Text("All Levels")
                    if selectedLevel == nil { Image(systemName: "checkmark") }
                }
            }
            Divider()
            ForEach(LogLevel.allCases, id: \.self) { level in
                Button {
                    selectedLevel = selectedLevel == level ? nil : level
                } label: {
                    HStack {
                        Text(level.displayName)
                        if selectedLevel == level { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            Image(systemName: selectedLevel == nil
                  ? "line.3.horizontal.decrease.circle"
                  : "line.3.horizontal.decrease.circle.fill")
        }
    }

    private var actionsMenu: some View {
        Menu {
            Button {
                UIPasteboard.general.string = formattedText(for: filteredEntries)
            } label: {
                Label("Copy Visible", systemImage: "doc.on.doc")
            }

            ShareLink(item: formattedText(for: appLogger.entries)) {
                Label("Export All as File", systemImage: "square.and.arrow.up")
            }

            Divider()

            Button(role: .destructive) {
                appLogger.clear()
            } label: {
                Label("Clear Logs", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    private var filteredEntries: [LogEntry] {
        appLogger.entries
            .filter { entry in
                if let level = selectedLevel, entry.level != level { return false }
                guard !searchText.isEmpty else { return true }
                return entry.message.localizedCaseInsensitiveContains(searchText)
                    || entry.category.localizedCaseInsensitiveContains(searchText)
            }
            .reversed()
    }

    private func formattedText(for entries: [LogEntry]) -> String {
        let formatter = ISO8601DateFormatter()
        return entries.map { entry in
            "[\(formatter.string(from: entry.timestamp))] [\(entry.level.rawValue.uppercased())] [\(entry.category)] \(entry.message)"
        }.joined(separator: "\n")
    }
}

private struct LogEntryRow: View {
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: entry.level.symbolName)
                    .foregroundStyle(entry.level.rowColor)
                    .imageScale(.small)

                Text(entry.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(entry.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Text(entry.message)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(4)
        }
        .padding(.vertical, 2)
    }
}

private extension LogLevel {
    var displayName: String {
        switch self {
        case .debug: return "Debug"
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }

    var symbolName: String {
        switch self {
        case .debug: return "ant.circle"
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        }
    }

    var rowColor: Color {
        switch self {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}
