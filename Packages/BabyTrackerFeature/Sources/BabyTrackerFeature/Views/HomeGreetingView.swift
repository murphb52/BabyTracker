import SwiftUI

struct HomeGreetingView<Accessory: View>: View {
    let accessory: Accessory

    init(@ViewBuilder accessory: () -> Accessory) {
        self.accessory = accessory()
    }

    var body: some View {
        TimelineView(.everyMinute) { context in
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateLabel(for: context.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(greeting(for: context.date))
                        .font(.largeTitle.bold())
                        .foregroundStyle(.primary)
                }

                Spacer(minLength: 12)

                accessory
                    .padding(.top, 2)
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

extension HomeGreetingView where Accessory == EmptyView {
    init() {
        self.accessory = EmptyView()
    }
}

#Preview("Default") {
    HomeGreetingView()
        .padding()
}

#Preview("With accessory") {
    HomeGreetingView {
        Image(systemName: "person.crop.circle")
            .font(.title2)
            .frame(width: 44, height: 44)
            .background(.thinMaterial, in: Circle())
    }
    .padding()
}
