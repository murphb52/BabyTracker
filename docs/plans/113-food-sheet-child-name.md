# 113 Food sheet child name

## Goal

The child's name is shown incorrectly on the food logging sheet. Review all logging sheets and fix any with the same problem.

## Approach

1. The food sheet puts the child's name in a `Section` title. Form section headers are uppercased by SwiftUI, so the name renders as "WHAT DID ROBYN HAVE?". Use a custom header with `.textCase(nil)` so the name keeps its casing.
2. Review the other sheets (nappy, bath, bottle, breast, sleep, medication). They only use the name in the summary sentence, which is unaffected. No changes needed.
3. Fix the food preset accessibility label, which was missing string interpolation.

- [x] Complete
