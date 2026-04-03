import SwiftUI

public struct TimelineDayGridItemView: View {
    let item: TimelineDayGridItemViewState
    let height: CGFloat
    let canManageEvents: Bool
    let openItem: (TimelineDayGridItemViewState) -> Void
    let deleteItem: (TimelineDayGridItemViewState) -> Void
    let pendingDeleteEvent: EventDeleteCandidate?
    let confirmDelete: () -> Void
    let cancelDelete: () -> Void

    public init(
        item: TimelineDayGridItemViewState,
        height: CGFloat,
        canManageEvents: Bool,
        openItem: @escaping (TimelineDayGridItemViewState) -> Void,
        deleteItem: @escaping (TimelineDayGridItemViewState) -> Void,
        pendingDeleteEvent: EventDeleteCandidate?,
        confirmDelete: @escaping () -> Void,
        cancelDelete: @escaping () -> Void
    ) {
        self.item = item
        self.height = height
        self.canManageEvents = canManageEvents
        self.openItem = openItem
        self.deleteItem = deleteItem
        self.pendingDeleteEvent = pendingDeleteEvent
        self.confirmDelete = confirmDelete
        self.cancelDelete = cancelDelete
    }

    public var body: some View {
        let isPendingDelete = pendingDeleteEvent?.id == item.primaryEventID
        let base = content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(BabyEventStyle.timelineFillColor(for: item.eventKind))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(BabyEventStyle.timelineBorderColor(for: item.eventKind), lineWidth: 1)
            )

        ZStack(alignment: .bottomTrailing) {
            if canManageEvents && item.isInteractive {
                Button {
                    openItem(item)
                } label: {
                    base
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .contextMenu {
                    Button("Edit") {
                        openItem(item)
                    }

                    Button("Delete", role: .destructive) {
                        deleteItem(item)
                    }
                }
            } else {
                base
            }

            if isPendingDelete, let pendingDeleteEvent {
                AnchoredDeletePromptView(
                    title: "Delete \(pendingDeleteEvent.title.lowercased())?",
                    confirmTitle: pendingDeleteEvent.confirmButtonTitle,
                    confirmAction: confirmDelete,
                    cancelAction: cancelDelete
                )
                .padding(8)
            }
        }
        .accessibilityIdentifier("timeline-day-grid-item-\(item.id)")
        .accessibilityLabel(accessibilityLabelText)
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(height > 66 ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                .lineLimit(1)

            if height > 52, !item.detailText.isEmpty {
                Text(item.detailText)
                    .font(.caption2)
                    .lineLimit(height > 92 ? 2 : 1)
            }

            if height > 78, !item.timeText.isEmpty {
                Text(item.timeText)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .opacity(0.85)
            }
        }
        .foregroundStyle(BabyEventStyle.timelineForegroundColor(for: item.eventKind))
    }

    private var accessibilityLabelText: String {
        [item.title, item.detailText, item.timeText]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
