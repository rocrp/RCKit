// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [:]
    )
#endif

let package = Package(
    name: "RCKit",
    dependencies: [
        .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.4.1"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.10.0"),
    ]
)
