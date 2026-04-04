import BabyTrackerDomain
import SwiftUI

public struct EventHistoryView: View {
    let viewModel: EventHistoryViewModel
    let canManageEvents: Bool
    let openEvent: (EventCardViewState) -> Void
    let deleteEvent: (EventCardViewState) -> Void
    let pendingDeleteEvent: EventDeleteCandidate?
    let confirmDelete: () -> Void
    let cancelDelete: () -> Void
    let onRefresh: () async -> Void

    public init(
        viewModel: EventHistoryViewModel,
        canManageEvents: Bool,
        openEvent: @escaping (EventCardViewState) -> Void,
        deleteEvent: @escaping (EventCardViewState) -> Void,
        pendingDeleteEvent: EventDeleteCandidate?,
        confirmDelete: @escaping () -> Void,
        cancelDelete: @escaping () -> Void,
        onRefresh: @escaping () async -> Void
    ) {
        self.viewModel = viewModel
        self.canManageEvents = canManageEvents
        self.openEvent = openEvent
        self.deleteEvent = deleteEvent
        self.pendingDeleteEvent = pendingDeleteEvent
        self.confirmDelete = confirmDelete
        self.cancelDelete = cancelDelete
        self.onRefresh = onRefresh
    }

    public var body: some View {
        VStack(spacing: 0) {
            if !viewModel.activeFilter.isEmpty {
                filterPillsBar
            }

            List {
                if viewModel.sections.isEmpty {
                    emptyState
                        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.sections) { section in
                        Section {
                            ForEach(section.events) { event in
                                eventRow(for: event)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                        } header: {
                            sectionHeader(for: section.date)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .refreshable {
                await onRefresh()
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Filter pills

    private var filterPillsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ActiveFilterPill.pills(for: viewModel.activeFilter)) { pill in
                    filterPill(pill)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    private func filterPill(_ pill: ActiveFilterPill) -> some View {
        HStack(spacing: 4) {
            Text(pill.label)
                .font(.subheadline.weight(.medium))

            Button {
                viewModel.updateFilter(pill.removing(from: viewModel.activeFilter))
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
            }
            .accessibilityLabel("Remove \(pill.label) filter")
        }
        .foregroundStyle(.white)
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .padding(.vertical, 6)
        .background(Capsule().fill(pill.color))
    }

    // MARK: - Event rows

    @ViewBuilder
    private func eventRow(for event: EventCardViewState) -> some View {
        let isPendingDelete = pendingDeleteEvent?.id == event.id

        if canManageEvents {
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    openEvent(event)
                } label: {
                    EventCardView(event: event)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("event-history-event-\(event.id.uuidString)")
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button(primaryActionTitle(for: event)) {
                        openEvent(event)
                    }
                }
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        deleteEvent(event)
                    }
                }
                .contextMenu {
                    Button(primaryActionTitle(for: event)) {
                        openEvent(event)
                    }
                    Button("Delete", role: .destructive) {
                        deleteEvent(event)
                    }
                }

                if isPendingDelete, let pendingDeleteEvent {
                    AnchoredDeletePromptView(
                        title: "Delete \(pendingDeleteEvent.title.lowercased())?",
                        confirmTitle: pendingDeleteEvent.confirmButtonTitle,
                        confirmAction: confirmDelete,
                        cancelAction: cancelDelete
                    )
                    .accessibilityIdentifier("event-history-delete-confirm-\(event.id.uuidString)")
                }
            }
        } else {
            EventCardView(event: event)
                .accessibilityIdentifier("event-history-event-\(event.id.uuidString)")
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.emptyStateTitle)
                .font(.headline)
            Text(viewModel.emptyStateMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
        .accessibilityIdentifier("event-history-empty-state")
    }

    private func primaryActionTitle(for event: EventCardViewState) -> String {
        switch event.actionPayload {
        case .endSleep:
            "End"
        case .editBreastFeed, .editBottleFeed, .editNappy, .editSleep:
            "Edit"
        }
    }

    private func sectionHeader(for date: Date) -> some View {
        Text(date.formatted(date: .abbreviated, time: .omitted))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.none)
    }
}

// MARK: - Active filter pills

struct ActiveFilterPill: Identifiable {
    enum Criterion {
        case eventType(BabyEventKind)
        case nappyType(NappyType)
        case milkType(MilkType)
        case breastSide(BreastSide)
        case sleepMin
        case sleepMax
        case occurredOnOrAfter
        case occurredOnOrBefore
    }

    let id: String
    let label: String
    let color: Color
    let criterion: Criterion

    func removing(from filter: EventFilter) -> EventFilter {
        var updated = filter
        switch criterion {
        case .eventType(let kind): updated.eventTypes.remove(kind)
        case .nappyType(let type): updated.nappyTypes.remove(type)
        case .milkType(let type): updated.milkTypes.remove(type)
        case .breastSide(let side): updated.breastSides.remove(side)
        case .sleepMin: updated.sleepMinDurationMinutes = nil
        case .sleepMax: updated.sleepMaxDurationMinutes = nil
        case .occurredOnOrAfter: updated.occurredOnOrAfter = nil
        case .occurredOnOrBefore: updated.occurredOnOrBefore = nil
        }
        return updated
    }

    static func pills(for filter: EventFilter) -> [ActiveFilterPill] {
        var pills: [ActiveFilterPill] = []

        for kind in [BabyEventKind.breastFeed, .bottleFeed, .sleep, .nappy]
            where filter.eventTypes.contains(kind) {
            pills.append(ActiveFilterPill(
                id: "eventType_\(kind.rawValue)",
                label: BabyEventPresentation.title(for: kind),
                color: BabyEventStyle.accentColor(for: kind),
                criterion: .eventType(kind)
            ))
        }

        for type in NappyType.allCases where filter.nappyTypes.contains(type) {
            pills.append(ActiveFilterPill(
                id: "nappyType_\(type.rawValue)",
                label: type.pillLabel,
                color: BabyEventStyle.accentColor(for: .nappy),
                criterion: .nappyType(type)
            ))
        }

        for type in MilkType.allCases where filter.milkTypes.contains(type) {
            pills.append(ActiveFilterPill(
                id: "milkType_\(type.rawValue)",
                label: type.pillLabel,
                color: BabyEventStyle.accentColor(for: .bottleFeed),
                criterion: .milkType(type)
            ))
        }

        for side in BreastSide.allCases where filter.breastSides.contains(side) {
            pills.append(ActiveFilterPill(
                id: "breastSide_\(side.rawValue)",
                label: side.pillLabel,
                color: BabyEventStyle.accentColor(for: .breastFeed),
                criterion: .breastSide(side)
            ))
        }

        if let min = filter.sleepMinDurationMinutes {
            pills.append(ActiveFilterPill(
                id: "sleepMin_\(min)",
                label: "≥ \(min) min",
                color: BabyEventStyle.accentColor(for: .sleep),
                criterion: .sleepMin
            ))
        }

        if let max = filter.sleepMaxDurationMinutes {
            pills.append(ActiveFilterPill(
                id: "sleepMax_\(max)",
                label: "≤ \(max) min",
                color: BabyEventStyle.accentColor(for: .sleep),
                criterion: .sleepMax
            ))
        }

        if let date = filter.occurredOnOrAfter {
            pills.append(ActiveFilterPill(
                id: "occurredOnOrAfter",
                label: "From \(date.formatted(date: .abbreviated, time: .omitted))",
                color: .indigo,
                criterion: .occurredOnOrAfter
            ))
        }

        if let date = filter.occurredOnOrBefore {
            pills.append(ActiveFilterPill(
                id: "occurredOnOrBefore",
                label: "To \(date.formatted(date: .abbreviated, time: .omitted))",
                color: .indigo,
                criterion: .occurredOnOrBefore
            ))
        }

        return pills
    }
}

// MARK: - Pill labels

private extension NappyType {
    var pillLabel: String {
        switch self {
        case .dry: "Dry"
        case .wee: "Wee"
        case .poo: "Poo"
        case .mixed: "Mixed"
        }
    }
}

private extension MilkType {
    var pillLabel: String {
        switch self {
        case .breastMilk: "Breast Milk"
        case .formula: "Formula"
        case .mixed: "Mixed"
        case .other: "Other"
        }
    }
}

private extension BreastSide {
    var pillLabel: String {
        switch self {
        case .left: "Left side"
        case .right: "Right side"
        case .both: "Both sides"
        }
    }
}

#Preview {
    let model = ChildProfilePreviewFactory.makeModel()
    let viewModel = EventHistoryViewModel(appModel: model)

    return EventHistoryView(
        viewModel: viewModel,
        canManageEvents: true,
        openEvent: { _ in },
        deleteEvent: { _ in },
        pendingDeleteEvent: nil,
        confirmDelete: {},
        cancelDelete: {},
        onRefresh: { await Task.yield() }
    )
}
