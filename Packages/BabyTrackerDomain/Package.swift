// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BabyTrackerDomain",
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
