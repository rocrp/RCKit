import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(
    name: "RCKit",
    destinations: [.iPhone, .iPad, .mac],
    dependencies: [
        .xcframework(
            path: "../../Dependencies/NSLoggerSwift.xcframework",
            status: .optional,
            condition: .when([.ios])
        )
    ]
)
