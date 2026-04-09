# 049 — Reimagined Summary Tab

GitHub Issue: murphb52/BabyTracker#161

## Goal

Redesign the Summary tab's Today segment into rich, full-width section cards — one per category — each showing metrics and a cumulative line chart comparing today's progress against the 7-day daily average. Fix two issues in the Trends segment: x-axis crowding on the 30-day view, and the `bottle.fill` SF Symbol not rendering (replaced with `drop.fill`).

Animation is explicitly out of scope for this plan and will be a separate pairing session.

---

## Today Tab Changes

Replace the 2-column metric card grid + extras row with vertical full-width section cards:

1. **Bottle** — total mL (formula / breast milk breakdown), last feed time, avg interval, time since last feed + cumulative mL chart
2. **Breast** — session count, total + avg duration + cumulative session chart
3. **Sleep** — total, longest, shortest, avg session, time since last sleep + cumulative minutes chart
4. **Nappies** — breakdown by type (wet / dirty / mixed / dry) + cumulative count chart
5. **More Information** link (moved from Trends)
6. **Logging streak** row

Each chart shows: solid line = today's cumulative total by hour, dotted line = 7-day average cumulative by hour.

---

## Trends Tab Changes

- X-axis: show every Nth label for dense ranges (≈6 labels for 30-day view)
- Replace `bottle.fill` with `drop.fill` (renders correctly across all targets)

---

## Implementation Steps

- [x] 1. Create branch `feature/reimagined-summary-tab`
- [x] 2. Data types + calculator — `HourlyCumulativeSeries`, `TodayChartData`, additions to `TodaySummaryData` + `TodaySummaryCalculator`; new tests in `TodaySummaryCalculatorTests`
- [x] 3. `CumulativeLineChartView` component
- [x] 4. Today tab: Bottle + Breast section cards
- [x] 5. Today tab: Sleep + Nappies section cards + footer
- [x] 6. Trends: x-axis thinning + bottle icon fix
- [x] 7. Preview factory enrichment

---

## Key Design Decisions

- **Cumulative line chart**: x = hour of day (0–23), y = running total. Solid line for today, dotted line for 7-day average.
- **7-day avg denominator**: always 7 (including zero-activity days), so the average reflects typical daily volume and isn't inflated by sparse tracking periods.
- **Event attribution**: each event is attributed to the hour of `occurredAt` (bottle, nappy) or `endedAt` (breast, sleep) for the cumulative chart.
- **Sleep section**: shows "time since last sleep" (issue had a copy-paste error saying "time since last feed").

---

- [ ] Complete
