import BabyTrackerDomain
import BabyTrackerPersistence
import BabyTrackerSync
import SwiftUI
import UserNotifications

/// The interactive onboarding experience for new users.
///
/// Presented as a `fullScreenCover` from `AppRootView` whenever
/// `model.isInteractiveOnboardingActive` is true (set by `AppModel.refresh()`
/// the first time a device has no local user). Persists across route changes
/// so the user/child creation steps do not dismiss the flow prematurely.
public struct InteractiveOnboardingView: View {
    let model: AppModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var currentStepIndex = 0
    @State private var caregiverName = ""
    @State private var childName = ""
    @State private var includesBirthDate = false
    @State private var babyBirthDate = Date()
    @State private var viewOpacity = 0.0
    @State private var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isShowingNotificationPermissionPrompt = false

    private static let welcomePage = OnboardingIntroPage(
        id: "welcome",
        title: "When every hour blurs together",
        message: "Feeds, nappies, and short stretches of sleep are hard to keep track of when you're running on empty.",
        symbolNames: [
            "clock.badge.questionmark.fill",
            "drop.fill",
            "moon.zzz.fill",
        ],
        highlights: [
            OnboardingIntroHighlight(title: "Last feed", symbolName: "drop.fill"),
            OnboardingIntroHighlight(title: "Last sleep", symbolName: "moon.zzz.fill"),
        ]
    )

    private enum Step: Int {
        case welcome = 0
        case quickLogDemo
        case timelineDemo
        case chartsDemo
        case caregiverName
        case babySetup
        case firstEvent
        case appPreview

        var isSkippableToSetup: Bool {
            switch self {
            case .welcome, .quickLogDemo, .timelineDemo, .chartsDemo:
                return true
            default:
                return false
            }
        }
    }

    private var currentStep: Step {
        Step(rawValue: currentStepIndex) ?? .welcome
    }

    private var trimmedCaregiverName: String {
        caregiverName.trimmingCharacters(in: .whitespaces)
    }

    private var trimmedChildName: String {
        childName.trimmingCharacters(in: .whitespaces)
    }

    public init(model: AppModel) {
        self.model = model
    }

    init(model: AppModel, previewStepIndex: Int) {
        self.model = model
        _currentStepIndex = State(initialValue: previewStepIndex)
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

                stepContent
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: currentStepIndex)

                Spacer(minLength: 24)

                footer
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
        .task {
            await refreshNotificationStatus()
        }
        .onAppear {
            guard !reduceMotion else {
                viewOpacity = 1
                return
            }
            withAnimation(.easeIn(duration: 0.2)) {
                viewOpacity = 1
            }
        }
        .opacity(viewOpacity)
        .alert("Enable Notifications?", isPresented: $isShowingNotificationPermissionPrompt) {
            Button("Enable Notifications", action: requestNotificationAuthorization)
            Button("Not Now", role: .cancel, action: { advance() })
        } message: {
            Text("Get a heads-up when another caregiver logs an event so you stay in the loop.")
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Text("Nest")
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()

            // Skip to caregiver name step from demo pages
            if currentStep.isSkippableToSetup {
                Button("Skip") {
                    move(to: Step.caregiverName.rawValue)
                }
                .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    // MARK: - Step content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .welcome:
            VStack(spacing: 24) {
                TabView(selection: .constant(0)) {
                    OnboardingIntroStepView(page: Self.welcomePage)
                        .tag(0)
                        .padding(.horizontal, 24)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageIndicator
            }

        case .quickLogDemo:
            demoPage(
                title: "Log in seconds",
                message: "Tap one button, fill in the details, done. No fumbling around."
            ) {
                OnboardingQuickLogDemoView()
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            }

        case .timelineDemo:
            demoPage(
                title: "See the whole picture",
                message: "The timeline fills in as you log, so you can see the rhythm of any day at a glance."
            ) {
                OnboardingTimelineDemoView()
            }

        case .chartsDemo:
            demoPage(
                title: "Spot the patterns",
                message: "The Summary tab turns raw events into charts so you can see what's changing week by week."
            ) {
                OnboardingChartsDemoView()
            }

        case .caregiverName:
            IdentityOnboardingNameStepView(
                displayName: $caregiverName,
                submitAction: submitCaregiverName
            )

        case .babySetup:
            OnboardingAddBabyStepView(
                childName: $childName,
                includesBirthDate: $includesBirthDate,
                birthDate: $babyBirthDate,
                addAction: submitBabySetup,
                skipAction: dismissOnboarding
            )

        case .firstEvent:
            OnboardingFirstEventStepView(
                model: model,
                onEventSaved: { advance() },
                skipAction: dismissOnboarding
            )

        case .appPreview:
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Here's your app")
                        .font(.largeTitle.weight(.bold))

                    Text("Everything you just logged is already there.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 16)

                OnboardingAppPreviewStepView(model: model)
            }
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        switch currentStep {
        case .welcome, .quickLogDemo, .timelineDemo, .chartsDemo:
            Button(action: advance) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)

        case .caregiverName:
            Button(action: submitCaregiverName) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .disabled(trimmedCaregiverName.isEmpty)

        case .babySetup:
            VStack(spacing: 12) {
                Button(action: submitBabySetup) {
                    Text("Add Baby")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .disabled(trimmedChildName.isEmpty)

                Button(action: dismissOnboarding) {
                    Text("Skip for now")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

        case .firstEvent:
            Button(action: dismissOnboarding) {
                Text("Skip for now")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

        case .appPreview:
            Button(action: dismissOnboarding) {
                Text("Let's Go")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Page indicator (shown on demo steps 0–3)

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4) { index in
                Capsule()
                    .fill(index == currentStepIndex ? Color.accentColor : Color.secondary.opacity(0.18))
                    .frame(width: index == currentStepIndex ? 28 : 10, height: 10)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding step \(currentStepIndex + 1) of 4")
    }

    // MARK: - Demo page layout

    @ViewBuilder
    private func demoPage<Demo: View>(
        title: String,
        message: String,
        @ViewBuilder demo: () -> Demo
    ) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)

                Text(message)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 20)

            demo()
                .padding(.horizontal, 24)

            pageIndicator
                .padding(.top, 20)
        }
    }

    // MARK: - Step actions

    private func advance() {
        move(to: currentStepIndex + 1)
    }

    private func move(to index: Int) {
        guard !reduceMotion else {
            currentStepIndex = index
            return
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStepIndex = index
        }
    }

    private func submitCaregiverName() {
        guard !trimmedCaregiverName.isEmpty else { return }
        model.createLocalUser(displayName: trimmedCaregiverName)
        // Offer notification permission before moving to baby setup
        if notificationAuthorizationStatus == .notDetermined {
            isShowingNotificationPermissionPrompt = true
        } else {
            advance()
        }
    }

    private func submitBabySetup() {
        guard !trimmedChildName.isEmpty else { return }
        model.createChild(
            name: trimmedChildName,
            birthDate: includesBirthDate ? babyBirthDate : nil
        )
        advance()
    }

    private func dismissOnboarding() {
        model.isInteractiveOnboardingActive = false
    }

    // MARK: - Notification permission

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationAuthorizationStatus = settings.authorizationStatus
    }

    private func requestNotificationAuthorization() {
        model.requestNotificationAuthorizationIfNeeded()
        advance()
    }
}

// MARK: - Previews

#Preview("Welcome") {
    InteractiveOnboardingView(
        model: InteractiveOnboardingPreviewFactory.makeModel(),
        previewStepIndex: 0
    )
}

#Preview("Quick Log Demo") {
    InteractiveOnboardingView(
        model: InteractiveOnboardingPreviewFactory.makeModel(),
        previewStepIndex: 1
    )
}

#Preview("Timeline Demo") {
    InteractiveOnboardingView(
        model: InteractiveOnboardingPreviewFactory.makeModel(),
        previewStepIndex: 2
    )
}

#Preview("Charts Demo") {
    InteractiveOnboardingView(
        model: InteractiveOnboardingPreviewFactory.makeModel(),
        previewStepIndex: 3
    )
}

#Preview("Caregiver Name") {
    InteractiveOnboardingView(
        model: InteractiveOnboardingPreviewFactory.makeModel(),
        previewStepIndex: 4
    )
}

#Preview("Baby Setup") {
    InteractiveOnboardingView(
        model: InteractiveOnboardingPreviewFactory.makeModel(),
        previewStepIndex: 5
    )
}

#Preview("First Event") {
    InteractiveOnboardingView(
        model: ChildProfilePreviewFactory.makeModel(),
        previewStepIndex: 6
    )
}

#Preview("App Preview") {
    InteractiveOnboardingView(
        model: ChildProfilePreviewFactory.makeModel(),
        previewStepIndex: 7
    )
}

private enum InteractiveOnboardingPreviewFactory {
    @MainActor
    static func makeModel() -> AppModel {
        let suiteName = "InteractiveOnboardingPreview"
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
