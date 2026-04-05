// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "BabyTrackerDomain",
    platforms: [
        .iOS(.v26),
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
        .testTarget(
            name: "BabyTrackerDomainTests",
            dependencies: ["BabyTrackerDomain"]
        ),
    ]
)
