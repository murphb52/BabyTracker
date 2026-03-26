import BabyTrackerDomain
import SwiftUI
import UIKit

public struct ChildPickerView: View {
    let model: AppModel

    public init(model: AppModel) {
        self.model = model
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Who are you tracking today?")
                    .font(.title2.weight(.bold))
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    ForEach(model.activeChildren) { summary in
                        childCard(for: summary)
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Choose Profile")
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private func childCard(for summary: ChildSummary) -> some View {
        Button {
            model.selectChild(id: summary.child.id)
        } label: {
            HStack(spacing: 16) {
                childAvatar(for: summary.child)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.child.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let ageText = ageString(for: summary.child.birthDate) {
                        Text(ageText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                roleBadge(for: summary.membership.role)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("child-picker-\(summary.child.id.uuidString)")
    }

    @ViewBuilder
    private func childAvatar(for child: Child) -> some View {
        if let imageData = child.imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(Circle())
        } else {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                Text(child.name.prefix(1).uppercased())
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    @ViewBuilder
    private func roleBadge(for role: MembershipRole) -> some View {
        let isOwner = role == .owner
        Text(isOwner ? "Owner" : "Caregiver")
            .font(.caption.weight(.semibold))
            .foregroundStyle(isOwner ? Color.accentColor : Color(.systemGray))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isOwner ? Color.accentColor.opacity(0.12) : Color(.systemGray5))
            )
    }

    private func ageString(for birthDate: Date?) -> String? {
        guard let birthDate else { return nil }
        let components = Calendar.current.dateComponents(
            [.year, .month, .weekOfYear],
            from: birthDate,
            to: Date()
        )
        if let years = components.year, years > 0 {
            return years == 1 ? "1 year old" : "\(years) years old"
        }
        if let months = components.month, months > 0 {
            return months == 1 ? "1 month old" : "\(months) months old"
        }
        if let weeks = components.weekOfYear, weeks > 0 {
            return weeks == 1 ? "1 week old" : "\(weeks) weeks old"
        }
        return "Newborn"
    }
}
