// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BabyTrackerPersistence",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "BabyTrackerPersistence",
            targets: ["BabyTrackerPersistence"]
        ),
    ],
    dependencies: [
        .package(path: "../BabyTrackerDomain"),
    ],
    targets: [
        .target(
            name: "BabyTrackerPersistence",
            dependencies: [
                .product(name: "BabyTrackerDomain", package: "BabyTrackerDomain"),
            ]
        ),
    ]
)
