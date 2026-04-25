# 101 — Home Screen Refresh: Greeting, Hero & Today Timeline

## Goal

Enhance the home screen with four features inspired by a design mockup:

1. **Time-of-day greeting** — "Good evening" + date at the top
2. **Hero sentence** — narrative snapshot ("Emily's been asleep ~4¾ hrs. Last fed at 17:34.")
3. **Hero card** — live sleep timer (redesigned) OR awake window card when not sleeping
4. **Today timeline** — vertical event timeline with a "Now" marker

The existing Quick Log, Current Status, and Sync sections are kept as-is.

## Layout (scroll order)

```
Greeting header        ← NEW
Hero sentence          ← NEW
Hero card              ← sleep card redesigned + new awake card
Quick Log              ← unchanged
Current Status         ← unchanged
Today timeline         ← NEW
Sync                   ← unchanged
```

## New files

### View state types

- `HomeTimelineEventViewState.swift` — id, kind, title, detailText, timeText (HH:mm), isOngoing
- `HomeAwakeHeroCardViewState.swift` — awakeStartedAt: Date?

### Views

- `HomeGreetingView.swift` — greeting + date + child avatar pill; updates via TimelineView(.everyMinute)
- `HomeAwakeHeroCardView.swift` — awake duration + Start nap / Log past sleep buttons
- `HomeTodayTimelineView.swift` — Now row + event rows (time | connector | icon + title + detail)

## Modified files

- `CurrentSleepCardView.swift` — large h/m/s timer, pulsing dot, keep Stop/Log past actions
- `HomeViewModel.swift` — add childName, awakeHeroCard, todayTimelineEvents
- `ChildHomeView.swift` — new layout, hero sentence text, awake card branch

## Hero sentence logic

- **Sleeping:** "{name}'s been asleep ~{Xh Xm}. Last fed at {HH:mm}."
- **Awake:** "{name}'s been awake {Xh Xm}. Last fed at {HH:mm}."
- Duration updates every second (TimelineView periodic); falls back gracefully when no data

## Greeting ranges

- 05:00–11:59 → Good morning
- 12:00–16:59 → Good afternoon
- 17:00–20:59 → Good evening
- 21:00–04:59 → Good night

- [x] Complete
