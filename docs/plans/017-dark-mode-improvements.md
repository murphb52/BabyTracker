# 017 Dark Mode Improvements

## Summary

Conduct a full dark mode styling audit across the app, resolve contrast problems caused by colored surfaces, and keep the event-color visual language readable in both appearances.

## Implementation

1. Add semantic event color mappings for icon badges, event cards, timeline blocks, and prominent quick actions instead of reusing a single light-mode palette everywhere.
2. Update Home, Events, and Timeline to use those semantic colors so dark mode keeps tinted event surfaces while preserving readable foreground text and borders.
3. Move elevated neutral surfaces onto grouped system backgrounds that separate properly in dark mode, including current status cards, picker cards, onboarding input chrome, delete prompts, and instructional panels.
4. Tighten chip and preset styling in the editor flows so selected and unselected states remain visually distinct in dark mode.
5. Add targeted contrast tests for event card and prominent event surface color pairs.

- [x] Complete
