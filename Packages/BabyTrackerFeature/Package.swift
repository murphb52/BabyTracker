// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BabyTrackerFeature",
    platforms: [
        .iOS(.v17),
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
    ],
    targets: [
        .target(
            name: "BabyTrackerFeature",
            dependencies: [
                .product(name: "BabyTrackerDomain", package: "BabyTrackerDomain"),
                .product(name: "BabyTrackerPersistence", package: "BabyTrackerPersistence"),
            ]
        ),
    ]
)
