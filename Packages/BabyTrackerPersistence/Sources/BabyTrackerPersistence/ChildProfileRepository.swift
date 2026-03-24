// ChildProfileRepository has been split into focused protocols.
// Use the appropriate protocol for each consumer:
//
//   ChildRepository          — child CRUD and CloudKit context
//   UserIdentityRepository   — user identity and CloudKit user linking
//   MembershipRepository     — membership CRUD
//   ChildSelectionStore      — selected child UI preference
