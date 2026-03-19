// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BabyTrackerSync",
    products: [
        .library(
            name: "BabyTrackerSync",
            targets: ["BabyTrackerSync"]
        ),
    ],
    dependencies: [
        .package(path: "../BabyTrackerDomain"),
        .package(path: "../BabyTrackerPersistence"),
    ],
    targets: [
        .target(
            name: "BabyTrackerSync",
            dependencies: [
                .product(name: "BabyTrackerDomain", package: "BabyTrackerDomain"),
                .product(name: "BabyTrackerPersistence", package: "BabyTrackerPersistence"),
            ]
        ),
    ]
)
