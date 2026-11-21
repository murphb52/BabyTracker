// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "BabyTrackerAssistant",
    platforms: [
        .iOS(.v26),
    ],
    products: [
        .library(
            name: "BabyTrackerAssistant",
            targets: ["BabyTrackerAssistant"]
        ),
    ],
    dependencies: [
        .package(path: "../BabyTrackerDomain"),
    ],
    targets: [
        .target(
            name: "BabyTrackerAssistant",
            dependencies: [
                .product(name: "BabyTrackerDomain", package: "BabyTrackerDomain"),
            ]
        ),
        .testTarget(
            name: "BabyTrackerAssistantTests",
            dependencies: [
                "BabyTrackerAssistant",
                .product(name: "BabyTrackerDomain", package: "BabyTrackerDomain"),
            ]
        ),
    ]
)
