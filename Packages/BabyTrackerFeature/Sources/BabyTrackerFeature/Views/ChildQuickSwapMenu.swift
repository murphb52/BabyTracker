import BabyTrackerDomain
import SwiftUI
import TipKit
import UIKit

struct ChildQuickSwapMenu: View {
    let currentChild: Child
    let children: [ChildSummary]
    let quickSwapTip: ChildQuickSwapTip
    let viewChild: (UUID) -> Void
    let setActiveChild: (UUID) -> Void
    let showNextChild: () -> Void

    private var hasMultipleChildren: Bool {
        children.count > 1
    }

    @ViewBuilder
    var body: some View {
        if hasMultipleChildren {
            menuContent
                .popoverTip(quickSwapTip)
        } else {
            menuContent
        }
    }

    private var menuContent: some View {
        Menu {
            ForEach(children) { summary in
                Section(summary.child.name) {
                    Button {
                        viewChild(summary.child.id)
                    } label: {
                        Label("View Profile", systemImage: "person.crop.circle")
                    }

                    Button {
                        setActiveChild(summary.child.id)
                    } label: {
                        Label(
                            summary.child.id == currentChild.id ? "Active Child" : "Set Active",
                            systemImage: summary.child.id == currentChild.id
                                ? "checkmark.circle.fill"
                                : "arrow.triangle.2.circlepath"
                        )
                    }
                    .disabled(summary.child.id == currentChild.id)
                }
            }
        } label: {
            ChildAvatarStackView(
                currentChild: currentChild,
                children: children
            )
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(hasMultipleChildren ? "Child quick swap" : "View child profile")
        .accessibilityHint(
            hasMultipleChildren
                ? "Swipe down to switch children or tap for child actions."
                : "Tap for child actions."
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 18)
                .onEnded { value in
                    guard hasMultipleChildren, value.translation.height > 24 else {
                        return
                    }

                    showNextChild()
                }
        )
    }
}

private struct ChildAvatarStackView: View {
    let currentChild: Child
    let children: [ChildSummary]

    private var visibleChildren: [Child] {
        var orderedChildren = children.map(\.child)
        orderedChildren.removeAll { child in
            child.id == currentChild.id
        }
        orderedChildren.insert(currentChild, at: 0)
        return Array(orderedChildren.prefix(3))
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)

            ForEach(Array(visibleChildren.enumerated()), id: \.element.id) { index, child in
                ChildAvatarCircleView(child: child, size: avatarSize)
                    .offset(x: horizontalPadding + CGFloat(index) * avatarSpacing)
                    .zIndex(Double(visibleChildren.count - index))
            }
        }
        .frame(width: stackWidth, height: 38, alignment: .leading)
        .contentShape(Capsule())
    }

    private var avatarSize: CGFloat {
        28
    }

    private var avatarSpacing: CGFloat {
        16
    }

    private var horizontalPadding: CGFloat {
        5
    }

    private var stackWidth: CGFloat {
        avatarSize + horizontalPadding * 2 + CGFloat(visibleChildren.count - 1) * avatarSpacing
    }
}

private struct ChildAvatarCircleView: View {
    let child: Child
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(.secondarySystemGroupedBackground))
                .frame(width: size, height: size)

            avatarContent
                .frame(width: size - 4, height: size - 4)
                .clipShape(Circle())
        }
        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
        .shadow(color: Color.black.opacity(0.08), radius: 3, y: 1)
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let imageData = child.imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Circle()
                .fill(Color.accentColor.opacity(0.14))
                .overlay {
                    Text(initials(for: child.name))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
        }
    }

    private func initials(for name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return words.prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased()
        }
        return String(name.prefix(1)).uppercased()
    }
}

struct ChildQuickSwapTip: Tip {
    var title: Text {
        Text("Quick swap children")
    }

    var message: Text? {
        Text("Swipe down on the child stack to switch. Tap it to view or set the active child.")
    }

    var image: Image? {
        Image(systemName: "arrow.down.circle")
    }
}

#Preview {
    let ownerID = UUID()
    let poppy = try! Child(name: "Poppy", createdBy: ownerID)
    let juniper = try! Child(name: "Juniper", createdBy: ownerID)
    let children = [poppy, juniper].map { child in
        ChildSummary(
            child: child,
            membership: .owner(childID: child.id, userID: ownerID)
        )
    }

    ChildQuickSwapMenu(
        currentChild: poppy,
        children: children,
        quickSwapTip: ChildQuickSwapTip(),
        viewChild: { _ in },
        setActiveChild: { _ in },
        showNextChild: {}
    )
    .padding()
}
