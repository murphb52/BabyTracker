// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BabyTrackerDomain",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "BabyTrackerDomain",
            targets: ["BabyTrackerDomain"]
        ),
    ],
    targets: [
        .target(
            name: "BabyTrackerDomain"
        ),
    ]
)
