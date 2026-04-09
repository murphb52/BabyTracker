# 021 Support oz feeding unit

1. Add a domain-level feeding volume unit (`mL` or `oz`) and conversion helpers so all formatting and conversion rules are centralized.
2. Persist each child's preferred feeding unit in SwiftData and include it in CloudKit child mapping.
3. Update feature state builders so bottle feed details and compact timeline text respect the selected unit.
4. Add a profile-level setting so caregivers can switch the preferred feeding unit for the active child.
5. Update bottle feed editor input/output to accept and display amounts in the selected unit while storing values in milliliters.
6. Add and update tests for conversion, persistence/mapping, and UI-facing formatted output.

- [x] Complete
