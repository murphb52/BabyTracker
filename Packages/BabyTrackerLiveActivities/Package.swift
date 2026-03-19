// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BabyTrackerLiveActivities",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "BabyTrackerLiveActivities",
            targets: ["BabyTrackerLiveActivities"]
        ),
    ],
    dependencies: [
        .package(path: "../BabyTrackerDomain"),
    ],
    targets: [
        .target(
            name: "BabyTrackerLiveActivities",
            dependencies: [
                .product(name: "BabyTrackerDomain", package: "BabyTrackerDomain"),
            ]
        ),
    ]
)
