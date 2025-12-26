import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.macOSApp(
    name: "RCKitDemoMacApp",
    dependencies: [
        .project(target: "SharedUI", path: "../SharedUI"),
        .xcframework(
            path: "../../Dependencies/MMKV.xcframework",
            status: .optional,
            condition: .when([.macos])
        ),
    ],
    infoPlistExtension: [
        "NSBonjourServices": [
            "_nslogger._tcp",
            "_nslogger-ssl._tcp",
        ],
        "NSLocalNetworkUsageDescription": "Access to the local network for development builds",
    ]
)
