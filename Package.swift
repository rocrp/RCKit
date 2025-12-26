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
    dependencies: [
        .package(url: "https://github.com/fpillet/NSLogger", branch: "master")
    ],
    targets: [
        .target(
            name: "RCKit",
            dependencies: [
                .product(name: "NSLogger", package: "NSLogger")
            ],
            swiftSettings: [
                .enableExperimentalFeature("ApproachableConcurrency")
            ]
        ),
        .testTarget(
            name: "RCKitTests",
            dependencies: ["RCKit"]
        ),
    ]
)
