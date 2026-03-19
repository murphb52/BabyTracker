import BabyTrackerFeature

struct AppContainer {
    let rootState: AppRootState

    static let live = AppContainer(rootState: .foundation)
}
