import BabyTrackerDomain
import SwiftUI

struct HomeTodayTimelineView: View {
    let events: [HomeTimelineEventViewState]

    var body: some View {
        if events.isEmpty {
            emptyState
        } else {
            timelineCard
        }
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            nowRow
            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                HomeTimelineEventRow(
                    event: event,
                    isLast: index == events.count - 1
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        )
    }

    private var nowRow: some View {
        TimelineView(.everyMinute) { context in
            HStack(spacing: 0) {
                Text(context.date.formatted(.dateTime.hour().minute()))
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 52, alignment: .trailing)

                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 1)
                    .padding(.horizontal, 10)

                Text("Now")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .padding(.vertical, 6)
        }
    }

    private var emptyState: some View {
        Text("No events today")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}

private struct HomeTimelineEventRow: View {
    let event: HomeTimelineEventViewState
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Time column
            Text(event.timeText)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .trailing)
                .padding(.top, 4)

            // Connector column
            connectorColumn
                .frame(width: 30)

            // Content column
            HStack(spacing: 10) {
                Image(systemName: BabyEventStyle.systemImage(for: event.kind))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BabyEventStyle.accentColor(for: event.kind))
                    .frame(width: 28, height: 28)
                    .background(BabyEventStyle.backgroundColor(for: event.kind), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)

                    if !event.detailText.isEmpty {
                        Text(event.detailText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 10)
        }
    }

    private var connectorColumn: some View {
        ZStack(alignment: .top) {
            // Vertical line (hidden for last row)
            if !isLast {
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                    .padding(.top, 16)
            }

            // Dot: hollow ring for ongoing, filled for completed
            if event.isOngoing {
                Circle()
                    .stroke(BabyEventStyle.accentColor(for: event.kind), lineWidth: 2)
                    .frame(width: 10, height: 10)
                    .background(Color(.secondarySystemGroupedBackground), in: Circle())
                    .padding(.top, 6)
            } else {
                Circle()
                    .fill(BabyEventStyle.accentColor(for: event.kind))
                    .frame(width: 8, height: 8)
                    .padding(.top, 7)
            }
        }
    }
}

// MARK: - Previews

private let previewEventsFull: [HomeTimelineEventViewState] = [
    HomeTimelineEventViewState(
        id: UUID(), kind: .sleep,
        title: "Sleep started", detailText: "Going on 4h 45m",
        timeText: "6:20 PM", isOngoing: true
    ),
    HomeTimelineEventViewState(
        id: UUID(), kind: .breastFeed,
        title: "Breast feed", detailText: "10 min · left side",
        timeText: "5:34 PM", isOngoing: false
    ),
    HomeTimelineEventViewState(
        id: UUID(), kind: .nappy,
        title: "Nappy", detailText: "Poo · medium · yellow",
        timeText: "4:15 PM", isOngoing: false
    ),
    HomeTimelineEventViewState(
        id: UUID(), kind: .bottleFeed,
        title: "Bottle feed", detailText: "60 mL · formula",
        timeText: "3:48 PM", isOngoing: false
    ),
    HomeTimelineEventViewState(
        id: UUID(), kind: .sleep,
        title: "Nap ended", detailText: "1h 45m",
        timeText: "2:30 PM", isOngoing: false
    ),
    HomeTimelineEventViewState(
        id: UUID(), kind: .sleep,
        title: "Nap started", detailText: "",
        timeText: "12:45 PM", isOngoing: false
    ),
]

private let previewEventsAwake: [HomeTimelineEventViewState] = [
    HomeTimelineEventViewState(
        id: UUID(), kind: .bottleFeed,
        title: "Bottle feed", detailText: "90 mL · breast milk",
        timeText: "2:10 PM", isOngoing: false
    ),
    HomeTimelineEventViewState(
        id: UUID(), kind: .sleep,
        title: "Nap ended", detailText: "1h 30m",
        timeText: "1:40 PM", isOngoing: false
    ),
    HomeTimelineEventViewState(
        id: UUID(), kind: .nappy,
        title: "Nappy", detailText: "Pee · light",
        timeText: "11:20 AM", isOngoing: false
    ),
]

#Preview("Sleeping — ongoing + 5 events") {
    ScrollView {
        HomeTodayTimelineView(events: previewEventsFull)
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Awake — 3 past events") {
    ScrollView {
        HomeTodayTimelineView(events: previewEventsAwake)
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Single event") {
    ScrollView {
        HomeTodayTimelineView(events: [previewEventsFull[1]])
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty — no events today") {
    ScrollView {
        HomeTodayTimelineView(events: [])
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}
