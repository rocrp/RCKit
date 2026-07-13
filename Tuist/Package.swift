// swift-tools-version: 6.2
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // RCKit must be a dynamic framework to avoid duplicate symbols when linked from
        // multiple targets (SharedUI, RCKitDemoApp, RCKitDemoMacApp).
        // NSLogger is only used by RCKit, so keeping it static lets its ObjC symbols
        // (NSLoggerLibObjC) link correctly into the RCKit framework.
        productTypes: [
            "RCKit": .framework
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
