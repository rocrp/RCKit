// swift-tools-version: 6.0

// SPM manifest for external consumers. Tuist uses Project.swift for development.
// Keep both in sync when adding dependencies or changing build settings.
//
// Usage in consumer project:
//   .package(path: "../RCKit")  // or URL for remote
//   .product(name: "RCKit", package: "RCKit")

import PackageDescription

let package = Package(
    name: "RCKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "RCKit", targets: ["RCKit"])
    ],
    targets: [
        .binaryTarget(
            name: "NSLoggerSwift",
            path: "Dependencies/NSLoggerSwift.xcframework"
        ),
        .target(
            name: "RCKit",
            dependencies: [
                .target(name: "NSLoggerSwift", condition: .when(platforms: [.iOS]))
            ],
            path: "RCKit/Sources",
            swiftSettings: [
                .enableExperimentalFeature("ApproachableConcurrency")
            ]
        )
    ]
)
