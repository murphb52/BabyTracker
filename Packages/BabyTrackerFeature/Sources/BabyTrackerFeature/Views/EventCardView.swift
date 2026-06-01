import BabyTrackerDomain
import SwiftUI

public struct EventCardView: View {
    let event: EventCardViewState
    let pendingReminderDate: Date?
    let onCancelReminder: (() -> Void)?

    @State private var showCancelReminderAlert = false

    public init(
        event: EventCardViewState,
        pendingReminderDate: Date? = nil,
        onCancelReminder: (() -> Void)? = nil
    ) {
        self.event = event
        self.pendingReminderDate = pendingReminderDate
        self.onCancelReminder = onCancelReminder
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(BabyEventStyle.backgroundColor(for: event.kind))
                        .frame(width: 36, height: 36)

                    Image(systemName: BabyEventStyle.systemImage(for: event.kind))
                        .font(.headline)
                        .foregroundStyle(BabyEventStyle.accentColor(for: event.kind))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundStyle(BabyEventStyle.cardForegroundColor(for: event.kind))

                    Text(event.detailText)
                        .font(.subheadline)
                        .foregroundStyle(BabyEventStyle.cardSecondaryForegroundColor(for: event.kind))
                }

                Spacer(minLength: 12)

                Text(event.timestampText)
                    .font(.footnote)
                    .foregroundStyle(BabyEventStyle.cardSecondaryForegroundColor(for: event.kind))
                    .multilineTextAlignment(.trailing)
            }

            if let fireDate = pendingReminderDate {
                Divider()
                    .padding(.top, 10)
                HStack(spacing: 6) {
                    Image(systemName: "bell.fill")
                        .font(.caption)
                        .foregroundStyle(BabyEventStyle.accentColor(for: event.kind))
                    Text("Reminder: \(fireDate.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(BabyEventStyle.cardSecondaryForegroundColor(for: event.kind))
                    Spacer()
                    if onCancelReminder != nil {
                        Button {
                            showCancelReminderAlert = true
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Cancel reminder")
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BabyEventStyle.cardFillColor(for: event.kind))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(BabyEventStyle.timelineBorderColor(for: event.kind), lineWidth: 1)
        )
        .alert("Cancel Reminder?", isPresented: $showCancelReminderAlert) {
            Button("Cancel Reminder", role: .destructive) {
                onCancelReminder?()
            }
            Button("Keep It", role: .cancel) {}
        } message: {
            Text("The reminder will be removed and you won't be notified.")
        }
    }
}
