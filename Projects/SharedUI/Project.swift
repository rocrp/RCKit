import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(
    name: "SharedUI",
    destinations: [.iPhone, .iPad, .mac],
    dependencies: [
        .external(name: "RCKit"),
        .external(name: "GRDB"),
        .xcframework(
            path: "../../Dependencies/MMKV.xcframework",
            status: .optional,
            condition: .when([.ios, .macos])
        ),
    ]
)
