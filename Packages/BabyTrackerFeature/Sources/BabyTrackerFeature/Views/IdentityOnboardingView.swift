import BabyTrackerDomain
import BabyTrackerPersistence
import BabyTrackerSync
import SwiftUI

public struct IdentityOnboardingView: View {
    let model: AppModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentStepIndex = 0
    @State private var displayName = ""

    private static let introPages: [OnboardingIntroPage] = [
        OnboardingIntroPage(
            title: "Track every feed, sleep, and nappy",
            message: "Log the moments that matter without digging through a complicated setup.",
            symbolName: "drop.circle.fill"
        ),
        OnboardingIntroPage(
            title: "See patterns at a glance",
            message: "Use the Summary tab to spot daily rhythms and understand how your baby is doing over time.",
            symbolName: "chart.line.uptrend.xyaxis.circle.fill"
        ),
        OnboardingIntroPage(
            title: "Share with another caregiver",
            message: "Keep both parents in sync through iCloud so everyone is working from the same timeline.",
            symbolName: "person.2.circle.fill"
        ),
    ]

    private var trimmedName: String {
        displayName.trimmingCharacters(in: .whitespaces)
    }

    private var isShowingNameStep: Bool {
        currentStepIndex >= Self.introPages.count
    }

    public init(model: AppModel) {
        self.model = model
    }

    init(
        model: AppModel,
        previewStepIndex: Int,
        previewDisplayName: String = ""
    ) {
        self.model = model
        _currentStepIndex = State(initialValue: previewStepIndex)
        _displayName = State(initialValue: previewDisplayName)
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemGroupedBackground),
                    Color.accentColor.opacity(0.08),
                    Color(.systemGroupedBackground),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Group {
                    if isShowingNameStep {
                        IdentityOnboardingNameStepView(
                            displayName: $displayName,
                            submitAction: submitName
                        )
                    } else {
                        introPager
                    }
                }
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: currentStepIndex)

                Spacer(minLength: 24)

                footer
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Text("Baby Tracker")
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()

            if !isShowingNameStep {
                Button("Skip") {
                    moveToNameStep()
                }
                .font(.subheadline.weight(.semibold))
                .accessibilityIdentifier("identity-onboarding-skip-button")
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private var introPager: some View {
        VStack(spacing: 24) {
            TabView(selection: $currentStepIndex) {
                ForEach(Array(Self.introPages.enumerated()), id: \.offset) { index, page in
                    OnboardingIntroStepView(page: page)
                        .tag(index)
                        .padding(.horizontal, 24)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(Self.introPages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == currentStepIndex ? Color.accentColor : Color.secondary.opacity(0.18))
                        .frame(width: index == currentStepIndex ? 28 : 10, height: 10)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Onboarding step \(currentStepIndex + 1) of \(Self.introPages.count)")
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            if isShowingNameStep {
                Button(action: submitName) {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .disabled(trimmedName.isEmpty)
                .accessibilityIdentifier("identity-save-button")
            } else {
                Button {
                    advance()
                } label: {
                    Text(currentStepIndex == Self.introPages.count - 1 ? "Get Started" : "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("identity-onboarding-continue-button")
            }
        }
    }

    private func advance() {
        if currentStepIndex < Self.introPages.count - 1 {
            move(to: currentStepIndex + 1)
        } else {
            moveToNameStep()
        }
    }

    private func moveToNameStep() {
        move(to: Self.introPages.count)
    }

    private func move(to stepIndex: Int) {
        guard reduceMotion == false else {
            currentStepIndex = stepIndex
            return
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            currentStepIndex = stepIndex
        }
    }

    private func submitName() {
        guard !trimmedName.isEmpty else {
            return
        }

        model.createLocalUser(displayName: trimmedName)
    }
}

#Preview("Intro") {
    IdentityOnboardingView(
        model: IdentityOnboardingPreviewFactory.makeModel(),
        previewStepIndex: 0
    )
}

#Preview("Name Step") {
    IdentityOnboardingView(
        model: IdentityOnboardingPreviewFactory.makeModel(),
        previewStepIndex: 3,
        previewDisplayName: "Alex"
    )
}

private enum IdentityOnboardingPreviewFactory {
    @MainActor
    static func makeModel() -> AppModel {
        let suiteName = "IdentityOnboardingPreview"
        let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        userDefaults.removePersistentDomain(forName: suiteName)

        let store = try! BabyTrackerModelStore(isStoredInMemoryOnly: true)
        let childRepository = SwiftDataChildRepository(store: store)
        let userIdentityRepository = SwiftDataUserIdentityRepository(store: store, userDefaults: userDefaults)
        let membershipRepository = SwiftDataMembershipRepository(store: store)
        let childSelectionStore = UserDefaultsChildSelectionStore(userDefaults: userDefaults)
        let eventRepository = SwiftDataEventRepository(store: store)
        let syncStateRepository = SwiftDataSyncStateRepository(store: store)
        let recordMetadataRepository = SwiftDataCloudKitRecordMetadataRepository(store: store)
        let syncEngine = CloudKitSyncEngine(
            childRepository: childRepository,
            userIdentityRepository: userIdentityRepository,
            membershipRepository: membershipRepository,
            eventRepository: eventRepository,
            syncStateRepository: syncStateRepository,
            recordMetadataRepository: recordMetadataRepository,
            client: UnavailableCloudKitClient()
        )
        let model = AppModel(
            childRepository: childRepository,
            userIdentityRepository: userIdentityRepository,
            membershipRepository: membershipRepository,
            childSelectionStore: childSelectionStore,
            eventRepository: eventRepository,
            syncEngine: syncEngine,
            liveActivityManager: NoOpFeedLiveActivityManager(),
            liveActivityPreferenceStore: InMemoryLiveActivityPreferenceStore(),
            localNotificationManager: NoOpLocalNotificationManager(),
            hapticFeedbackProvider: NoOpHapticFeedbackProvider()
        )

        model.load(performLaunchSync: false)
        return model
    }
}
