import BabyTrackerDomain
import SwiftUI

public struct EventFilterView: View {
    let currentFilter: EventFilter
    let onApply: (EventFilter) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: EventFilter

    public init(
        currentFilter: EventFilter,
        onApply: @escaping (EventFilter) -> Void
    ) {
        self.currentFilter = currentFilter
        self.onApply = onApply
        self._draft = State(initialValue: currentFilter)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    eventTypeSection
                    dateSection
                    if shouldShowNappySection { nappyTypeSection }
                    if shouldShowMilkSection { milkTypeSection }
                    if shouldShowBreastSection { breastSideSection }
                    if shouldShowSleepSection { sleepDurationSection }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Filter Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        draft = .empty
                    }
                    .accessibilityIdentifier("event-filter-clear-button")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        onApply(normalizedDateRangeFilter(from: draft))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("event-filter-apply-button")
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Sections

    private var eventTypeSection: some View {
        filterCard("Event Type") {
            let kinds: [BabyEventKind] = [.breastFeed, .bottleFeed, .sleep, .nappy]
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(kinds, id: \.self) { kind in
                    eventKindChip(kind)
                }
            }
        }
    }

    private var nappyTypeSection: some View {
        filterCard("Nappy Type") {
            HStack(spacing: 8) {
                ForEach(NappyType.allCases, id: \.self) { type in
                    multiSelectChip(
                        label: type.displayName,
                        isSelected: draft.nappyTypes.contains(type),
                        color: BabyEventStyle.accentColor(for: .nappy)
                    ) { toggleMembership(type, in: \.nappyTypes) }
                }
            }
        }
    }

    private var dateSection: some View {
        filterCard("Date") {
            VStack(spacing: 12) {
                optionalDateRow(
                    title: "From",
                    keyPath: \.occurredOnOrAfter,
                    date: draft.occurredOnOrAfter,
                    normalizeDate: { Calendar.current.startOfDay(for: $0) },
                    setDateToNow: { draft.occurredOnOrAfter = Calendar.current.startOfDay(for: Date()) },
                    clearDate: { draft.occurredOnOrAfter = nil }
                )

                Divider()

                optionalDateRow(
                    title: "To",
                    keyPath: \.occurredOnOrBefore,
                    date: draft.occurredOnOrBefore,
                    normalizeDate: { endOfDay(for: $0) },
                    setDateToNow: { draft.occurredOnOrBefore = endOfDay(for: Date()) },
                    clearDate: { draft.occurredOnOrBefore = nil }
                )
            }
        }
    }

    private var milkTypeSection: some View {
        filterCard("Milk Type") {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(MilkType.allCases, id: \.self) { type in
                    multiSelectChip(
                        label: type.displayName,
                        isSelected: draft.milkTypes.contains(type),
                        color: BabyEventStyle.accentColor(for: .bottleFeed)
                    ) { toggleMembership(type, in: \.milkTypes) }
                }
            }
        }
    }

    private var breastSideSection: some View {
        filterCard("Breast Side") {
            HStack(spacing: 8) {
                ForEach(BreastSide.allCases, id: \.self) { side in
                    multiSelectChip(
                        label: side.displayName,
                        isSelected: draft.breastSides.contains(side),
                        color: BabyEventStyle.accentColor(for: .breastFeed)
                    ) { toggleMembership(side, in: \.breastSides) }
                }
            }
        }
    }

    private var sleepDurationSection: some View {
        filterCard("Sleep Duration") {
            VStack(spacing: 12) {
                durationRow(
                    label: "Minimum",
                    value: draft.sleepMinDurationMinutes,
                    onDecrement: {
                        let current = draft.sleepMinDurationMinutes ?? 0
                        draft.sleepMinDurationMinutes = current > 15 ? current - 15 : nil
                    },
                    onIncrement: {
                        draft.sleepMinDurationMinutes = (draft.sleepMinDurationMinutes ?? 0) + 15
                    }
                )

                Divider()

                durationRow(
                    label: "Maximum",
                    value: draft.sleepMaxDurationMinutes,
                    onDecrement: {
                        let current = draft.sleepMaxDurationMinutes ?? 0
                        draft.sleepMaxDurationMinutes = current > 15 ? current - 15 : nil
                    },
                    onIncrement: {
                        draft.sleepMaxDurationMinutes = (draft.sleepMaxDurationMinutes ?? 0) + 15
                    }
                )
            }
        }
    }

    // MARK: - Row/chip builders

    private func eventKindChip(_ kind: BabyEventKind) -> some View {
        let isSelected = draft.eventTypes.contains(kind)
        return Button {
            toggleMembership(kind, in: \.eventTypes)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: BabyEventPresentation.systemImage(for: kind))
                    .font(.body)
                Text(BabyEventPresentation.title(for: kind))
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected
                        ? BabyEventStyle.cardFillColor(for: kind)
                        : Color(.tertiarySystemGroupedBackground))
            )
            .foregroundStyle(isSelected
                ? BabyEventStyle.cardForegroundColor(for: kind)
                : Color.primary)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ? BabyEventStyle.accentColor(for: kind).opacity(0.35) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func multiSelectChip(
        label: String,
        isSelected: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? color : Color(.tertiarySystemGroupedBackground))
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func durationRow(
        label: String,
        value: Int?,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)

            Spacer()

            HStack(spacing: 12) {
                Button(action: onDecrement) {
                    Image(systemName: "minus")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color(.tertiarySystemGroupedBackground)))
                }
                .buttonStyle(.plain)
                .disabled(value == nil)

                Text(value.map { DurationText.short(minutes: $0, minuteStyle: .word) } ?? "Any")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(value == nil ? .secondary : .primary)
                    .frame(minWidth: 72)
                    .multilineTextAlignment(.center)

                Button(action: onIncrement) {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color(.tertiarySystemGroupedBackground)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func optionalDateRow(
        title: String,
        keyPath: WritableKeyPath<EventFilter, Date?>,
        date: Date?,
        normalizeDate: @escaping (Date) -> Date,
        setDateToNow: @escaping () -> Void,
        clearDate: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()

                if let date {
                    Button("Clear", role: .destructive, action: clearDate)
                        .font(.caption.weight(.semibold))
                        .buttonStyle(.borderless)
                } else {
                    Button("Set", action: setDateToNow)
                        .font(.caption.weight(.semibold))
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }

            if let date {
                DatePicker(
                    title,
                    selection: binding(for: keyPath, fallback: date, normalizeDate: normalizeDate),
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.graphical)
            } else {
                Text("Any date")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func filterCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Visibility

    private var shouldShowNappySection: Bool {
        draft.eventTypes.isEmpty || draft.eventTypes.contains(.nappy)
    }

    private var shouldShowMilkSection: Bool {
        draft.eventTypes.isEmpty || draft.eventTypes.contains(.bottleFeed)
    }

    private var shouldShowBreastSection: Bool {
        draft.eventTypes.isEmpty || draft.eventTypes.contains(.breastFeed)
    }

    private var shouldShowSleepSection: Bool {
        draft.eventTypes.isEmpty || draft.eventTypes.contains(.sleep)
    }

    // MARK: - Mutation

    private func toggleMembership<T: Hashable>(_ value: T, in keyPath: WritableKeyPath<EventFilter, Set<T>>) {
        var updated = draft
        if updated[keyPath: keyPath].contains(value) {
            updated[keyPath: keyPath].remove(value)
        } else {
            updated[keyPath: keyPath].insert(value)
        }
        draft = updated
    }

    private func binding(
        for keyPath: WritableKeyPath<EventFilter, Date?>,
        fallback: Date,
        normalizeDate: @escaping (Date) -> Date
    ) -> Binding<Date> {
        Binding<Date>(
            get: { draft[keyPath: keyPath] ?? fallback },
            set: { draft[keyPath: keyPath] = normalizeDate($0) }
        )
    }

    private func endOfDay(for date: Date) -> Date {
        let start = Calendar.current.startOfDay(for: date)
        return Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? start
    }

    private func normalizedDateRangeFilter(from filter: EventFilter) -> EventFilter {
        guard let from = filter.occurredOnOrAfter, let to = filter.occurredOnOrBefore, from > to else {
            return filter
        }

        var normalized = filter
        normalized.occurredOnOrAfter = to
        normalized.occurredOnOrBefore = from
        return normalized
    }
}

// MARK: - Display names

extension NappyType {
    fileprivate var displayName: String {
        switch self {
        case .dry: "Dry"
        case .wee: "Wee"
        case .poo: "Poo"
        case .mixed: "Mixed"
        }
    }
}

extension MilkType {
    fileprivate var displayName: String {
        switch self {
        case .breastMilk: "Breast Milk"
        case .formula: "Formula"
        case .mixed: "Mixed"
        case .other: "Other"
        }
    }
}

extension BreastSide {
    fileprivate var displayName: String {
        switch self {
        case .left: "Left"
        case .right: "Right"
        case .both: "Both"
        }
    }
}

#Preview {
    EventFilterView(
        currentFilter: EventFilter(
            eventTypes: [],
            nappyTypes: [],
            milkTypes: [],
            breastSides: [],
            sleepMinDurationMinutes: 75,
            sleepMaxDurationMinutes: 135,
            occurredOnOrAfter: nil,
            occurredOnOrBefore: nil
        )
    ) { _ in }
}
