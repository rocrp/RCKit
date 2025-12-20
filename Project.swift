import ProjectDescription

let project = Project(
    name: "RCKit",
    targets: [
        .target(
            name: "RCKit",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.RCKit",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            buildableFolders: [
                "RCKit/Sources",
                "RCKit/Resources",
            ],
            dependencies: []
        ),
        .target(
            name: "RCKitTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.RCKitTests",
            infoPlist: .default,
            buildableFolders: [
                "RCKit/Tests"
            ],
            dependencies: [.target(name: "RCKit")]
        ),
    ]
)
