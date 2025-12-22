// swift-tools-version: 6.2
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
                .enableExperimentalFeature("ApproachableConcurrency"),
            ]
        ),
        .testTarget(
            name: "RCKitTests",
            dependencies: ["RCKit"],
            path: "RCKit/Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
