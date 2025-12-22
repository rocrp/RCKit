import ProjectDescription

// App settings
let appSettings = Settings.settings(
    base: [
        "SWIFT_VERSION": "6.2",
        "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    ]
)

// Test settings
let testSettings = Settings.settings(
    base: [
        "SWIFT_VERSION": "6.2",
        "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
    ]
)

let macOSDeploymentTarget = "15.0"
let iOSDeploymentTarget = "18.0"

let project = Project(
    name: "RCKitDemo",
    options: .options(automaticSchemesOptions: .disabled),
    packages: [
        .local(path: "."),
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
    ],
    targets: [
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
            buildableFolders: ["RCKitDemo/Sources", "RCKitDemo/Resources"],
            dependencies: [
                .package(product: "RCKit"),
                .package(product: "GRDB"),
                .xcframework(
                    path: "Dependencies/MMKV.xcframework",
                    condition: .when([.ios, .macos])
                ),
                .xcframework(
                    path: "Dependencies/NSLoggerSwift.xcframework",
                    condition: .when([.ios])
                ),
            ],
            settings: appSettings
        ),
        .target(
            name: "RCKitDemoTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.rocry.RCKitDemoTests",
            deploymentTargets: .iOS(iOSDeploymentTarget),
            infoPlist: .default,
            buildableFolders: ["RCKitDemo/Tests"],
            dependencies: [
                .target(name: "RCKitDemo"),
                .package(product: "GRDB"),
                .xcframework(
                    path: "Dependencies/MMKV.xcframework",
                    condition: .when([.ios])
                ),
            ],
            settings: testSettings
        ),
    ],
    schemes: [
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
