// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BabyTrackerFeature",
    products: [
        .library(
            name: "BabyTrackerFeature",
            targets: ["BabyTrackerFeature"]
        ),
    ],
    dependencies: [
        .package(path: "../BabyTrackerDomain"),
    ],
    targets: [
        .target(
            name: "BabyTrackerFeature",
            dependencies: [
                .product(name: "BabyTrackerDomain", package: "BabyTrackerDomain"),
            ]
        ),
    ]
)
