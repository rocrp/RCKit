import ProjectDescription

let settings = Settings.settings(
    base: [
        "SWIFT_VERSION": "5.9",
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    ]
)

let frameworkSettings = Settings.settings(
    base: [
        "SWIFT_VERSION": "5.9",
        "ENABLE_MODULE_VERIFIER": "YES",
    ]
)

let macOSDeploymentTarget = "15.0"
let iOSDeploymentTarget = "18.0"

let project = Project(
    name: "RCKit",
    options: .options(automaticSchemesOptions: .disabled),
    packages: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0")
    ],
    settings: settings,
    targets: [
        .target(
            name: "RCKit",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "dev.rocry.RCKit",
            deploymentTargets: .multiplatform(iOS: iOSDeploymentTarget, macOS: macOSDeploymentTarget),
            infoPlist: .default,
            sources: ["RCKit/Sources/**"],
            dependencies: [
                .xcframework(
                    path: "Dependencies/NSLoggerSwift.xcframework",
                    condition: .when([.ios])
                )
            ],
            settings: frameworkSettings
        ),
        .target(
            name: "RCKitDemo",
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            bundleId: "dev.rocry.RCKitDemo",
            deploymentTargets: .multiplatform(iOS: iOSDeploymentTarget, macOS: macOSDeploymentTarget),
            infoPlist: .extendingDefault(
                with: [
                    // Keep an explicit launch screen; without it iOS can fall back to a legacy
                    // letterboxed layout on modern iPhones.
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "NSBonjourServices": [
                        "_nslogger._tcp",
                        "_nslogger-ssl._tcp",
                    ],
                    "NSLocalNetworkUsageDescription": "Access to the local network for development builds",
                ]
            ),
            sources: ["RCKitDemo/Sources/**"],
            resources: ["RCKitDemo/Resources/**"],
            dependencies: [
                .target(name: "RCKit"),
                .package(product: "GRDB"),
                .xcframework(
                    path: "Dependencies/MMKV.xcframework",
                    condition: .when([.ios, .macos])
                ),
                .xcframework(
                    path: "Dependencies/NSLoggerSwift.xcframework",
                    condition: .when([.ios])
                ),
            ]
        ),
        .target(
            name: "RCKitTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.rocry.RCKitTests",
            deploymentTargets: .iOS(iOSDeploymentTarget),
            infoPlist: .default,
            sources: ["RCKit/Tests/**"],
            dependencies: [.target(name: "RCKit")]
        ),
        .target(
            name: "RCKitDemoTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.rocry.RCKitDemoTests",
            deploymentTargets: .iOS(iOSDeploymentTarget),
            infoPlist: .default,
            sources: ["RCKitDemo/Tests/**"],
            dependencies: [
                .target(name: "RCKitDemo"),
                .package(product: "GRDB"),
                .xcframework(
                    path: "Dependencies/MMKV.xcframework",
                    condition: .when([.ios])
                ),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "RCKit",
            shared: true,
            buildAction: .buildAction(targets: [.target("RCKit")])
        ),
        .scheme(
            name: "RCKitDemo",
            shared: true,
            buildAction: .buildAction(targets: [.target("RCKitDemo")]),
            runAction: .runAction(
                configuration: .debug,
                executable: .target("RCKitDemo"),
                expandVariableFromTarget: .target("RCKitDemo")
            )
        ),
        .scheme(
            name: "RCKitTests",
            shared: true,
            buildAction: .buildAction(targets: [
                .target("RCKit"),
                .target("RCKitTests"),
            ]),
            testAction: .targets([
                .testableTarget(target: .target("RCKitTests"))
            ])
        ),
        .scheme(
            name: "RCKitDemoTests",
            shared: true,
            buildAction: .buildAction(targets: [
                .target("RCKitDemo"),
                .target("RCKitDemoTests"),
            ]),
            testAction: .targets([
                .testableTarget(target: .target("RCKitDemoTests"))
            ])
        ),
    ]
)
