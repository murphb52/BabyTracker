import BabyTrackerDomain
import SwiftUI

/// Custom mini-timeline demo for the "See the whole picture" onboarding page.
///
/// Five day-columns of event blocks fade in category by category — sleep first,
/// then feeds, then nappies — so the viewer can see how a full day fills in.
/// A legend then pops in item by item below the timeline.
struct OnboardingTimelineDemoView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var columnsVisible = false
    @State private var sleepVisible = false
    @State private var feedsVisible = false
    @State private var nappiesVisible = false
    @State private var sleepOffset: CGFloat = 14
    @State private var feedsOffset: CGFloat = 14
    @State private var nappiesOffset: CGFloat = 14
    @State private var legendMask: [Bool] = [false, false, false, false]

    private let columnHeight: CGFloat = 200

    private let legendItems: [(kind: BabyEventKind, label: String)] = [
        (.sleep, "Sleep"),
        (.breastFeed, "Breast Feed"),
        (.bottleFeed, "Bottle Feed"),
        (.nappy, "Nappy"),
    ]
    private let weekdayLabels = ["M", "T", "W", "T", "F"]

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 8) {
                // Mini timeline
                HStack(alignment: .top, spacing: 7) {
                    ForEach(0..<5, id: \.self) { col in
                        timelineColumn(col)
                    }
                }

                HStack(spacing: 7) {
                    ForEach(Array(weekdayLabels.enumerated()), id: \.offset) { _, label in
                        Text(label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .opacity(columnsVisible ? 1 : 0)
            .offset(y: columnsVisible ? 0 : 14)
            .animation(
                reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8),
                value: columnsVisible
            )

            // Legend
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 8
            ) {
                ForEach(Array(legendItems.enumerated()), id: \.offset) { index, item in
                    legendCell(kind: item.kind, label: item.label, index: index)
                }
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .onAppear {
            animate()
        }
    }

    // MARK: - Column

    private func timelineColumn(_ column: Int) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color(.quaternaryLabel).opacity(0.18))

            ForEach(blocks(for: column)) { block in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(BabyEventStyle.timelineFillColor(for: block.kind))
                    .frame(height: max(5, CGFloat(block.end - block.start) * columnHeight))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .offset(y: CGFloat(block.start) * columnHeight + blockOffset(for: block.kind))
                    .opacity(blockOpacity(for: block.kind))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: columnHeight)
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    private func blockOpacity(for kind: BabyEventKind) -> Double {
        switch kind {
        case .sleep:                    return sleepVisible   ? 1 : 0
        case .breastFeed, .bottleFeed:  return feedsVisible   ? 1 : 0
        case .nappy:                    return nappiesVisible ? 1 : 0
        default:                        return 0
        }
    }

    private func blockOffset(for kind: BabyEventKind) -> CGFloat {
        switch kind {
        case .sleep:                    return sleepOffset
        case .breastFeed, .bottleFeed:  return feedsOffset
        case .nappy:                    return nappiesOffset
        default:                        return 0
        }
    }

    // MARK: - Legend cell

    private func legendCell(kind: BabyEventKind, label: String, index: Int) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(BabyEventStyle.timelineFillColor(for: kind))
                .frame(width: 26, height: 12)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .opacity(legendMask[index] ? 1 : 0)
        .offset(y: legendMask[index] ? 0 : 6)
    }

    // MARK: - Animation

    private func animate() {
        if reduceMotion {
            columnsVisible = true
            sleepVisible = true
            feedsVisible = true
            nappiesVisible = true
            sleepOffset = 0
            feedsOffset = 0
            nappiesOffset = 0
            legendMask = [true, true, true, true]
            return
        }
        Task { @MainActor in
            // Wait for the page slide-in transition to land
            try? await Task.sleep(for: .milliseconds(420))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                columnsVisible = true
            }
            // Sleep blocks — most prominent, reveal first
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.easeInOut(duration: 0.55)) {
                sleepVisible = true
                sleepOffset = 0
            }
            // Feed blocks
            try? await Task.sleep(for: .milliseconds(700))
            withAnimation(.easeInOut(duration: 0.55)) {
                feedsVisible = true
                feedsOffset = 0
            }
            // Nappy blocks
            try? await Task.sleep(for: .milliseconds(600))
            withAnimation(.easeInOut(duration: 0.55)) {
                nappiesVisible = true
                nappiesOffset = 0
            }
            try? await Task.sleep(for: .milliseconds(820))
            // Legend items stagger in
            for i in 0..<legendItems.count {
                try? await Task.sleep(for: .milliseconds(160))
                withAnimation(.spring(response: 0.42, dampingFraction: 0.7)) {
                    legendMask[i] = true
                }
            }
        }
    }

    // MARK: - Sample data

    private struct Block: Identifiable {
        let id: Int
        let start: Double
        let end: Double
        let kind: BabyEventKind
    }

    private func blocks(for column: Int) -> [Block] {
        Self.sampleData
            .enumerated()
            .compactMap { index, entry in
                guard entry.column == column else { return nil }
                return Block(id: index, start: entry.start, end: entry.end, kind: entry.kind)
            }
    }

    private struct SampleEntry {
        let column: Int
        let start: Double
        let end: Double
        let kind: BabyEventKind
    }

    // start/end expressed as a fraction of the 24-hour day (0.0 = midnight, 1.0 = next midnight).
    // Five columns represent five days with slight timing variation so the pattern looks natural.
    private static let sampleData: [SampleEntry] = {
        func s(_ col: Int, _ start: Double, _ end: Double, _ kind: BabyEventKind) -> SampleEntry {
            SampleEntry(column: col, start: start, end: end, kind: kind)
        }
        return [
            // ── Night sleeps (midnight to ~5am) ──────────────────────
            s(0, 0.00, 0.21, .sleep), s(1, 0.00, 0.19, .sleep), s(2, 0.00, 0.22, .sleep),
            s(3, 0.00, 0.20, .sleep), s(4, 0.00, 0.18, .sleep),

            // ── Morning naps (~9–10am) ────────────────────────────────
            s(0, 0.38, 0.44, .sleep), s(1, 0.37, 0.42, .sleep), s(2, 0.39, 0.45, .sleep),
            s(3, 0.38, 0.43, .sleep), s(4, 0.36, 0.42, .sleep),

            // ── Afternoon naps (~1–2:30pm) ────────────────────────────
            s(0, 0.54, 0.61, .sleep), s(1, 0.55, 0.62, .sleep), s(2, 0.53, 0.60, .sleep),
            s(3, 0.54, 0.61, .sleep), s(4, 0.55, 0.63, .sleep),

            // ── Bedtime sleeps (~7:45pm onwards) ─────────────────────
            s(0, 0.82, 1.00, .sleep), s(1, 0.83, 1.00, .sleep), s(2, 0.81, 1.00, .sleep),
            s(3, 0.82, 1.00, .sleep), s(4, 0.84, 1.00, .sleep),

            // ── Morning feeds (~6am) ──────────────────────────────────
            s(0, 0.25, 0.29, .bottleFeed),  s(1, 0.24, 0.28, .breastFeed),
            s(2, 0.26, 0.30, .bottleFeed),  s(3, 0.25, 0.29, .breastFeed),
            s(4, 0.24, 0.28, .bottleFeed),

            // ── Mid-day feeds (~10:30am) ──────────────────────────────
            s(0, 0.45, 0.49, .breastFeed),  s(1, 0.44, 0.48, .bottleFeed),
            s(2, 0.46, 0.50, .breastFeed),  s(3, 0.44, 0.48, .bottleFeed),
            s(4, 0.43, 0.47, .breastFeed),

            // ── Afternoon feeds (~2:30pm) ─────────────────────────────
            s(0, 0.62, 0.66, .bottleFeed),  s(1, 0.63, 0.67, .breastFeed),
            s(2, 0.61, 0.65, .bottleFeed),  s(3, 0.62, 0.66, .breastFeed),
            s(4, 0.64, 0.68, .bottleFeed),

            // ── Evening feeds (~5:30pm) ───────────────────────────────
            s(0, 0.72, 0.76, .breastFeed),  s(1, 0.71, 0.75, .bottleFeed),
            s(2, 0.73, 0.77, .breastFeed),  s(3, 0.72, 0.76, .bottleFeed),
            s(4, 0.71, 0.75, .breastFeed),

            // ── Morning nappies (~7:15am) ─────────────────────────────
            s(0, 0.30, 0.312, .nappy), s(1, 0.29, 0.302, .nappy),
            s(2, 0.31, 0.322, .nappy), s(3, 0.30, 0.312, .nappy),
            s(4, 0.29, 0.302, .nappy),

            // ── Mid-day nappies (~11:45am) ────────────────────────────
            s(0, 0.49, 0.502, .nappy), s(1, 0.48, 0.492, .nappy),
            s(2, 0.50, 0.512, .nappy), s(3, 0.49, 0.502, .nappy),
            s(4, 0.48, 0.492, .nappy),

            // ── Afternoon nappies (~3:30pm) ───────────────────────────
            s(0, 0.66, 0.672, .nappy), s(1, 0.67, 0.682, .nappy),
            s(2, 0.65, 0.662, .nappy), s(3, 0.66, 0.672, .nappy),
            s(4, 0.68, 0.692, .nappy),

            // ── Evening nappies (~6pm) ────────────────────────────────
            s(0, 0.76, 0.772, .nappy), s(1, 0.75, 0.762, .nappy),
            s(2, 0.77, 0.782, .nappy), s(3, 0.76, 0.772, .nappy),
            s(4, 0.75, 0.762, .nappy),
        ]
    }()
}

#Preview {
    OnboardingTimelineDemoView()
        .padding(.horizontal, 24)
}
