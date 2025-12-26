// swift-tools-version: 6.2
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Use dynamic frameworks to avoid "static product may introduce unwanted side effects"
        // when the same dependency is linked from multiple targets (e.g., SharedUI and apps)
        productTypes: [
            "RCKit": .framework,
            "NSLogger": .framework,
        ]
    )
#endif

let package = Package(
    name: "RCKitDeps",
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
    ]
)
