// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "BabyTrackerFeature",
    platforms: [
        .iOS(.v26),
    ],
    products: [
        .library(
            name: "BabyTrackerFeature",
            targets: ["BabyTrackerFeature"]
        ),
    ],
    dependencies: [
        .package(path: "../BabyTrackerDomain"),
        .package(path: "../BabyTrackerPersistence"),
        .package(path: "../BabyTrackerSync"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0"),
    ],
    targets: [
        .target(
            name: "BabyTrackerFeature",
            dependencies: [
                .product(name: "BabyTrackerDomain", package: "BabyTrackerDomain"),
                .product(name: "BabyTrackerPersistence", package: "BabyTrackerPersistence"),
                .product(name: "BabyTrackerSync", package: "BabyTrackerSync"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
            ]
        ),
        .testTarget(
            name: "BabyTrackerFeatureTests",
            dependencies: [
                "BabyTrackerFeature",
                .product(name: "BabyTrackerDomain", package: "BabyTrackerDomain"),
            ]
        ),
    ]
)
