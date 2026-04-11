import BabyTrackerDomain
import BabyTrackerPersistence
import BabyTrackerSync
import SwiftUI
import UserNotifications

public struct IdentityOnboardingView: View {
    let model: AppModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentStepIndex = 0
    @State private var displayName = ""
    @State private var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isShowingNotificationPermissionPrompt = false
    @State private var isHandlingNotificationPermissionFlow = false
    @State private var hasShownNotificationPermissionPrompt = false
    @State private var viewOpacity = 0.0
    @State private var isExiting = false

    private static let introPages: [OnboardingIntroPage] = [
        OnboardingIntroPage(
            id: "pain-points",
            title: "When every hour blurs together",
            message: "Feeds, nappies, and short stretches of sleep are hard to keep in your head when you're already running on empty.",
            symbolNames: [
                "clock.badge.questionmark.fill",
                "drop.fill",
                "moon.zzz.fill",
            ],
            highlights: [
                OnboardingIntroHighlight(title: "Last feed", symbolName: "drop.fill"),
                OnboardingIntroHighlight(title: "Last sleep", symbolName: "moon.zzz.fill"),
            ]
        ),
        OnboardingIntroPage(
            id: "app-help",
            title: "Log it fast, find the pattern",
            message: "Capture what happened in seconds, then use the timeline and summary views to see what your baby actually needs.",
            symbolNames: [
                "square.and.pencil.circle.fill",
                "list.bullet.clipboard.fill",
                "chart.line.uptrend.xyaxis.circle.fill",
            ],
            highlights: [
                OnboardingIntroHighlight(title: "Quick logging", symbolName: "checkmark.circle.fill"),
                OnboardingIntroHighlight(title: "Daily summaries", symbolName: "chart.bar.fill"),
            ]
        ),
        OnboardingIntroPage(
            id: "sharing",
            title: "Share the load without extra texting",
            message: "Invite another caregiver, keep one live timeline in sync, and get a notification when they log an event so you stay in the loop.",
            symbolNames: [
                "person.2.circle.fill",
                "bell.badge.fill",
                "arrow.triangle.2.circlepath.circle.fill",
            ],
            highlights: [
                OnboardingIntroHighlight(title: "Easy sharing", symbolName: "person.badge.plus.fill"),
                OnboardingIntroHighlight(title: "Helpful alerts", symbolName: "bell.badge.fill"),
            ]
        ),
        OnboardingIntroPage(
            id: "security",
            title: "Private by default, shared only by you",
            message: "Everything stays on your device and in iCloud, so only you and the caregivers you invite can see your baby's timeline.",
            symbolNames: [
                "lock.shield.fill",
                "icloud.fill",
                "checkmark.seal.fill",
            ],
            highlights: [
                OnboardingIntroHighlight(title: "Private in iCloud", symbolName: "icloud.fill"),
                OnboardingIntroHighlight(title: "Invite-only access", symbolName: "lock.fill"),
            ]
        ),
    ]

    private var trimmedName: String {
        displayName.trimmingCharacters(in: .whitespaces)
    }

    private var isShowingNameStep: Bool {
        currentStepIndex >= Self.introPages.count
    }

    private var shouldSkipProfileSetupStep: Bool {
        model.localUser != nil
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
            .allowsHitTesting(isExiting == false)

            if isShowingNotificationPermissionPrompt {
                Color.black.opacity(0.22)
                    .ignoresSafeArea()
                    .transition(.opacity)

                OnboardingNotificationPromptView(
                    enableAction: requestNotificationAuthorization,
                    skipAction: dismissNotificationPromptAndContinue
                )
                .padding(.horizontal, 24)
                .transition(.scale(scale: 0.96).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .task {
            await refreshNotificationAuthorizationStatus()
        }
        .onAppear {
            guard reduceMotion == false else {
                viewOpacity = 1
                return
            }

            withAnimation(.easeIn(duration: 0.2)) {
                viewOpacity = 1
            }
        }
        .opacity(viewOpacity)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isShowingNotificationPermissionPrompt)
    }

    private var topBar: some View {
        HStack {
            Text("Nest")
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()

            if isShowingNameStep && !model.activeChildren.isEmpty {
                Button("Close") {
                    model.dismissOnboarding()
                }
                .font(.subheadline.weight(.semibold))
                .accessibilityIdentifier("identity-onboarding-close-button")
            } else if !isShowingNameStep {
                Button(shouldSkipProfileSetupStep ? "Close" : "Skip") {
                    finishIntro()
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
                    Text(primaryActionTitle)
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
        guard isHandlingNotificationPermissionFlow == false else {
            return
        }

        if currentIntroPage?.id == "sharing",
           hasShownNotificationPermissionPrompt == false,
           notificationAuthorizationStatus == .notDetermined {
            hasShownNotificationPermissionPrompt = true
            isShowingNotificationPermissionPrompt = true
            return
        }

        moveToNextIntroStep()
    }

    private var primaryActionTitle: String {
        guard currentStepIndex == Self.introPages.count - 1 else {
            return "Continue"
        }

        return shouldSkipProfileSetupStep ? "Done" : "Get Started"
    }

    private var currentIntroPage: OnboardingIntroPage? {
        guard Self.introPages.indices.contains(currentStepIndex) else {
            return nil
        }

        return Self.introPages[currentStepIndex]
    }

    private func moveToNameStep() {
        move(to: Self.introPages.count)
    }

    private func finishIntro() {
        guard shouldSkipProfileSetupStep else {
            moveToNameStep()
            return
        }

        performExit {
            model.dismissOnboarding()
        }
    }

    private func moveToNextIntroStep() {
        if currentStepIndex < Self.introPages.count - 1 {
            move(to: currentStepIndex + 1)
        } else {
            finishIntro()
        }
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

        performExit {
            model.createLocalUser(displayName: trimmedName)
        }
    }

    private func requestNotificationAuthorization() {
        Task { @MainActor in
            guard isHandlingNotificationPermissionFlow == false else {
                return
            }

            isHandlingNotificationPermissionFlow = true
            isShowingNotificationPermissionPrompt = false
            model.requestNotificationAuthorizationIfNeeded()
            isHandlingNotificationPermissionFlow = false
        }
    }

    private func dismissNotificationPromptAndContinue() {
        isShowingNotificationPermissionPrompt = false
        moveToNextIntroStep()
    }

    private func refreshNotificationAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationAuthorizationStatus = settings.authorizationStatus
    }

    private func performExit(_ action: @escaping () -> Void) {
        guard isExiting == false else {
            return
        }

        guard reduceMotion == false else {
            action()
            return
        }

        isExiting = true
        withAnimation(.easeOut(duration: 0.18)) {
            viewOpacity = 0
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else {
                return
            }

            action()
        }
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

#Preview("Replay Intro") {
    IdentityOnboardingView(
        model: IdentityOnboardingPreviewFactory.makeModel(withLocalUser: true),
        previewStepIndex: 0
    )
}

private enum IdentityOnboardingPreviewFactory {
    @MainActor
    static func makeModel(withLocalUser: Bool = false) -> AppModel {
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

        if withLocalUser {
            model.createLocalUser(displayName: "Alex Parent")
        }
        model.load(performLaunchSync: false)
        return model
    }
}
