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
        .package(path: "../BabyTrackerLiveActivities"),
        .package(path: "../BabyTrackerPersistence"),
        .package(path: "../BabyTrackerSync"),
    ],
    targets: [
        .target(
            name: "BabyTrackerFeature",
            dependencies: [
                .product(name: "BabyTrackerDomain", package: "BabyTrackerDomain"),
                .product(name: "BabyTrackerLiveActivities", package: "BabyTrackerLiveActivities"),
                .product(name: "BabyTrackerPersistence", package: "BabyTrackerPersistence"),
                .product(name: "BabyTrackerSync", package: "BabyTrackerSync"),
            ]
        ),
        .testTarget(
            name: "BabyTrackerFeatureTests",
            dependencies: ["BabyTrackerFeature"]
        ),
    ]
)
