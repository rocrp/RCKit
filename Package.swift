// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "RCKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
    ],
    products: [
        .library(name: "RCKit", targets: ["RCKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/rocrp/neologger.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "RCKit",
            dependencies: [
                .product(name: "NeoLogger", package: "neologger")
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
