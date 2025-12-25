import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.macOSApp(
    name: "RCKitDemoMacApp",
    dependencies: [
        .project(target: "SharedUI", path: "../SharedUI"),
        .project(target: "RCKit", path: "../RCKit"),
        .xcframework(
            path: "../../Dependencies/MMKV.xcframework",
            status: .optional,
            condition: .when([.macos])
        ),
    ]
)
