import SwiftUI

struct HomeGreetingView: View {
    var body: some View {
        TimelineView(.everyMinute) { context in
            VStack(alignment: .leading, spacing: 2) {
                Text(dateLabel(for: context.date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(greeting(for: context.date))
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
            }
        }
    }

    private func greeting(for date: Date) -> String {
        let hour = Calendar.autoupdatingCurrent.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    private func dateLabel(for date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }
}

#Preview("Default") {
    HomeGreetingView()
        .padding()
}
