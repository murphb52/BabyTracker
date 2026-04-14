import FirebaseCore

public enum FirebaseBootstrapper {
    public static func configureIfNeeded() {
        guard FirebaseApp.app() == nil else {
            return
        }

        FirebaseApp.configure()
    }
}

