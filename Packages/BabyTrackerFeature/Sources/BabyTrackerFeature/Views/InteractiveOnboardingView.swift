import BabyTrackerDomain
import BabyTrackerPersistence
import BabyTrackerSync
import SwiftUI
import UIKit
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
    @Environment(\.openURL) private var openURL

    @State private var currentStepIndex = 0
    @State private var isGoingBack = false
    @State private var caregiverName = ""
    @State private var childName = ""
    @State private var includesBirthDate = false
    @State private var babyBirthDate = Date()
    @State private var viewOpacity = 0.0
    @State private var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var activeNotificationAlert: NotificationAlert?

    private static let welcomePage = OnboardingIntroPage(
        id: "welcome",
        title: "When you're tired and remembering is hard",
        message: "Feeds, nappies, and short stretches of sleep are easy to lose track of when you're exhausted with a baby.",
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
        case notificationsDemo
        case caregiverName
        case babySetup
        case firstEvent
        case appPreview

        var isSkippableToSetup: Bool {
            switch self {
            case .welcome, .quickLogDemo, .timelineDemo, .chartsDemo, .liveActivityDemo, .notificationsDemo:
                return true
            default:
                return false
            }
        }
    }

    private enum NotificationAlert: Identifiable {
        case prePrompt
        case denied

        var id: Int {
            switch self {
            case .prePrompt: return 0
            case .denied: return 1
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
        .alert(item: $activeNotificationAlert) { alert in
            switch alert {
            case .prePrompt:
                Alert(
                    title: Text("Enable Notifications?"),
                    message: Text("We'll show the system prompt next so Nest can send helpful alerts."),
                    primaryButton: .default(Text("Continue"), action: requestNotificationAuthorization),
                    secondaryButton: .cancel(Text("Not Now"), action: continueWithoutNotificationPermission)
                )
            case .denied:
                Alert(
                    title: Text("Notifications Are Off"),
                    message: Text("To enable alerts, update notification permissions for Nest in Settings."),
                    primaryButton: .default(Text("Open Settings"), action: openSettingsForNotifications),
                    secondaryButton: .cancel(Text("Not Now"), action: continueWithoutNotificationPermission)
                )
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Text("Nest")
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()

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
                title: "We're here to help",
                message: "Log quickly, spot patterns, and stay in sync with your partner without carrying it all in your head."
            ) {
                VStack(spacing: 16) {
                    OnboardingSupportHighlightsView()

                    OnboardingQuickLogDemoView()
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
                }
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

        case .notificationsDemo:
            OnboardingDemoPageContainer(
                title: "Get helpful alerts",
                message: "Know when feeds, sleep, and changes are logged, even when you're away from the app."
            ) {
                OnboardingNotificationsDemoView()
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
                OnboardingPrimaryButton(title: "Continue", action: advance)
            }

        case .notificationsDemo:
            VStack(spacing: 16) {
                pageIndicator
                OnboardingPrimaryButton(title: "Continue", action: handleNotificationsDemoContinue)
            }

        case .caregiverName:
            OnboardingPrimaryButton(
                title: "Get Started",
                action: submitCaregiverName,
                isDisabled: trimmedCaregiverName.isEmpty
            )

        case .babySetup:
            VStack(spacing: 12) {
                OnboardingPrimaryButton(
                    title: "Add Baby",
                    action: submitBabySetup,
                    isDisabled: trimmedChildName.isEmpty
                )

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
            OnboardingPrimaryButton(title: "Let's Go", action: dismissOnboarding)
        }
    }

    // MARK: - Page indicator (shown on demo steps 0–5)

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<6) { index in
                Capsule()
                    .fill(index == currentStepIndex ? Color.accentColor : Color.secondary.opacity(0.18))
                    .frame(width: index == currentStepIndex ? 28 : 10, height: 10)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding step \(currentStepIndex + 1) of 6")
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
        advance()
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

    private func handleNotificationsDemoContinue() {
        switch notificationAuthorizationStatus {
        case .authorized, .provisional, .ephemeral:
            advance()
        case .notDetermined:
            activeNotificationAlert = .prePrompt
        case .denied:
            activeNotificationAlert = .denied
        @unknown default:
            activeNotificationAlert = .prePrompt
        }
    }

    private func continueWithoutNotificationPermission() {
        advance()
    }

    private func openSettingsForNotifications() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            advance()
            return
        }
        openURL(url)
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

#Preview("Notifications Demo") {
    InteractiveOnboardingView(
        model: InteractiveOnboardingPreviewFactory.makeModel(),
        previewStepIndex: 5
    )
}

#Preview("Caregiver Name") {
    InteractiveOnboardingView(
        model: InteractiveOnboardingPreviewFactory.makeModel(),
        previewStepIndex: 6
    )
}

#Preview("Baby Setup") {
    InteractiveOnboardingView(
        model: InteractiveOnboardingPreviewFactory.makeModel(),
        previewStepIndex: 7
    )
}

#Preview("First Event") {
    InteractiveOnboardingView(
        model: ChildProfilePreviewFactory.makeModel(),
        previewStepIndex: 8
    )
}

#Preview("App Preview") {
    InteractiveOnboardingView(
        model: ChildProfilePreviewFactory.makeModel(),
        previewStepIndex: 9
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
