import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(
    name: "RCKit",
    destinations: [.iPhone, .iPad, .mac],
    dependencies: [
        .external(name: "NSLogger", condition: .when([.ios]))
    ]
)
