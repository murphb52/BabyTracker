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
    @State private var isGoingBack = false
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
        case liveActivityDemo
        case caregiverName
        case babySetup
        case firstEvent
        case appPreview

        var isSkippableToSetup: Bool {
            switch self {
            case .welcome, .quickLogDemo, .timelineDemo, .chartsDemo, .liveActivityDemo:
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
                    .id(currentStepIndex)
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .move(edge: isGoingBack ? .leading : .trailing).combined(with: .opacity),
                        removal: .move(edge: isGoingBack ? .trailing : .leading).combined(with: .opacity)
                    ))

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
        .gesture(
            DragGesture()
                .onEnded { value in
                    let isRightSwipe = value.translation.width > 60
                    let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                    guard isRightSwipe && isHorizontal && currentStepIndex > 0 else { return }
                    goBack()
                }
        )
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
            TabView(selection: .constant(0)) {
                OnboardingIntroStepView(page: Self.welcomePage)
                    .tag(0)
                    .padding(.horizontal, 24)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

        case .quickLogDemo:
            OnboardingDemoPageContainer(
                title: "Log in seconds",
                message: "Tap one button, fill in the details, done. No fumbling around."
            ) {
                OnboardingQuickLogDemoView()
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            }

        case .timelineDemo:
            OnboardingDemoPageContainer(
                title: "See the whole picture",
                message: "The timeline fills in as you log, so you can see the rhythm of any day at a glance."
            ) {
                OnboardingTimelineDemoView()
            }

        case .chartsDemo:
            OnboardingDemoPageContainer(
                title: "Spot the patterns",
                message: "The Summary tab turns raw events into charts so you can see what's changing week by week."
            ) {
                OnboardingChartsDemoView()
            }

        case .liveActivityDemo:
            OnboardingDemoPageContainer(
                title: "Stay updated from your Lock Screen",
                message: "See the latest feed, sleep, and nappy timings without unlocking your phone."
            ) {
                OnboardingLiveActivityDemoView()
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
            OnboardingAppPreviewStepView(model: model)
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        switch currentStep {
        case .welcome, .quickLogDemo, .timelineDemo, .chartsDemo, .liveActivityDemo:
            VStack(spacing: 16) {
                pageIndicator
                Button(action: advance) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
            }

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

    // MARK: - Page indicator (shown on demo steps 0–4)

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<5) { index in
                Capsule()
                    .fill(index == currentStepIndex ? Color.accentColor : Color.secondary.opacity(0.18))
                    .frame(width: index == currentStepIndex ? 28 : 10, height: 10)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding step \(currentStepIndex + 1) of 5")
    }

    // MARK: - Step actions

    private func advance() {
        move(to: currentStepIndex + 1)
    }

    private func goBack() {
        guard currentStepIndex > 0 else { return }
        move(to: currentStepIndex - 1)
    }

    private func move(to index: Int) {
        isGoingBack = index < currentStepIndex
        guard !reduceMotion else {
            currentStepIndex = index
            return
        }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
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

#Preview("Live Activity Demo") {
    InteractiveOnboardingView(
        model: InteractiveOnboardingPreviewFactory.makeModel(),
        previewStepIndex: 4
    )
}

#Preview("Caregiver Name") {
    InteractiveOnboardingView(
        model: InteractiveOnboardingPreviewFactory.makeModel(),
        previewStepIndex: 5
    )
}

#Preview("Baby Setup") {
    InteractiveOnboardingView(
        model: InteractiveOnboardingPreviewFactory.makeModel(),
        previewStepIndex: 6
    )
}

#Preview("First Event") {
    InteractiveOnboardingView(
        model: ChildProfilePreviewFactory.makeModel(),
        previewStepIndex: 7
    )
}

#Preview("App Preview") {
    InteractiveOnboardingView(
        model: ChildProfilePreviewFactory.makeModel(),
        previewStepIndex: 8
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
