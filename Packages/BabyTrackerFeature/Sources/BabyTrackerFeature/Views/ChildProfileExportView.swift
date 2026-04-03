import SwiftUI

public struct ChildProfileExportView: View {
    @State private var viewModel: ExportViewModel

    public init(appModel: AppModel) {
        _viewModel = State(initialValue: ExportViewModel(appModel: appModel))
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                idleView
            case .exporting:
                exportingView
            case .ready(let url):
                readyView(url: url)
            case .error(let message):
                errorView(message)
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.dismiss()
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Export your baby's data")
                        .font(.headline)
                    Text("Download a complete record of all logged events as a Nest JSON file. Share it with healthcare providers, keep a backup, or import it into another device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("What gets exported") {
                exportableRow(icon: "moon.zzz.fill", title: "Sleep sessions", color: .indigo)
                exportableRow(icon: "waterbottle.fill", title: "Bottle feeds (amount & milk type)", color: .blue)
                exportableRow(icon: "figure.seated.side.air.upper", title: "Breast feeds (side & duration)", color: .pink)
                exportableRow(icon: "checklist.checked", title: "Nappy changes (type, volume & colour)", color: .orange)
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Your data, your file", systemImage: "lock.shield")
                        .font(.subheadline)
                        .bold()
                    Text("The exported file stays on your device. Nest does not upload or share it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button {
                    viewModel.exportData()
                } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .accessibilityIdentifier("export-data-button")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Exporting

    private var exportingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
            Text("Preparing export…")
                .font(.headline)
            Text("Gathering all logged events.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Ready

    private func readyView(url: URL) -> some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text("Export Ready")
                        .font(.title2)
                        .bold()

                    Text("Your data has been prepared as a Nest JSON file.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section {
                ShareLink(item: url) {
                    Label("Share Export File", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .accessibilityIdentifier("share-export-file-button")

                Button {
                    viewModel.dismiss()
                } label: {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("export-done-button")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.red)

                    Text("Export Failed")
                        .font(.title2)
                        .bold()

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section {
                Button {
                    viewModel.dismiss()
                } label: {
                    Text("Try Again")
                        .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("export-retry-button")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Row helper

    private func exportableRow(icon: String, title: String, color: Color) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(color)
        }
    }
}
