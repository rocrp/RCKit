import ProjectDescription

// MARK: - Shared Settings

private let swiftSettings: SettingsDictionary = [
    "SWIFT_VERSION": "6.2",
    "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
]

private let iOSDeploymentTarget = "18.0"
private let macOSDeploymentTarget = "15.0"

// MARK: - Project Templates

public extension Project {
    static func iOSApp(
        name: String,
        dependencies: [TargetDependency] = [],
        infoPlistExtension: [String: Plist.Value] = [:]
    ) -> Project {
        var infoPlist: [String: Plist.Value] = [
            "CFBundleShortVersionString": "1.0",
            "CFBundleVersion": "1",
            "UILaunchScreen": [:],
            "UIApplicationSceneManifest": [
                "UIApplicationSupportsMultipleScenes": false,
                "UISceneConfigurations": [:],
            ],
        ]
        infoPlist.merge(infoPlistExtension) { _, new in new }

        return Project(
            name: name,
            targets: [
                .target(
                    name: name,
                    destinations: .iOS,
                    product: .app,
                    bundleId: "dev.rocry.\(name)",
                    deploymentTargets: .iOS(iOSDeploymentTarget),
                    infoPlist: .extendingDefault(with: infoPlist),
                    sources: ["Sources/**"],
                    resources: ["Resources/**"],
                    dependencies: dependencies,
                    settings: .settings(base: swiftSettings)
                )
            ]
        )
    }

    static func macOSApp(
        name: String,
        dependencies: [TargetDependency] = [],
        infoPlistExtension: [String: Plist.Value] = [:]
    ) -> Project {
        var infoPlist: [String: Plist.Value] = [
            "CFBundleShortVersionString": "1.0",
            "CFBundleVersion": "1",
        ]
        infoPlist.merge(infoPlistExtension) { _, new in new }

        return Project(
            name: name,
            targets: [
                .target(
                    name: name,
                    destinations: .macOS,
                    product: .app,
                    bundleId: "dev.rocry.\(name)",
                    deploymentTargets: .macOS(macOSDeploymentTarget),
                    infoPlist: .extendingDefault(with: infoPlist),
                    sources: ["Sources/**"],
                    resources: ["Resources/**"],
                    dependencies: dependencies,
                    settings: .settings(base: swiftSettings)
                )
            ]
        )
    }

    static func framework(
        name: String,
        destinations: Destinations = [.iPhone, .iPad, .mac],
        dependencies: [TargetDependency] = [],
        testDependencies: [TargetDependency] = []
    ) -> Project {
        var targets: [Target] = [
            .target(
                name: name,
                destinations: destinations,
                product: .framework,
                bundleId: "dev.rocry.\(name)",
                deploymentTargets: .multiplatform(iOS: iOSDeploymentTarget, macOS: macOSDeploymentTarget),
                infoPlist: .default,
                sources: ["Sources/**"],
                dependencies: dependencies,
                settings: .settings(
                    base: swiftSettings.merging([
                        "ENABLE_MODULE_VERIFIER": "YES"
                    ]) { _, new in new }
                )
            )
        ]

        // Add test target if Tests directory exists
        targets.append(
            .target(
                name: "\(name)Tests",
                destinations: destinations,
                product: .unitTests,
                bundleId: "dev.rocry.\(name)Tests",
                deploymentTargets: .multiplatform(iOS: iOSDeploymentTarget, macOS: macOSDeploymentTarget),
                infoPlist: .default,
                sources: ["Tests/**"],
                dependencies: [.target(name: name)] + testDependencies,
                settings: .settings(base: swiftSettings)
            )
        )

        let schemes: [Scheme] = [
            .scheme(
                name: name,
                shared: true,
                buildAction: .buildAction(targets: [.target(name)])
            ),
            .scheme(
                name: "\(name)Tests",
                shared: true,
                buildAction: .buildAction(targets: [
                    .target(name),
                    .target("\(name)Tests"),
                ]),
                testAction: .targets([
                    .testableTarget(target: .target("\(name)Tests"))
                ])
            ),
        ]

        return Project(
            name: name,
            options: .options(automaticSchemesOptions: .disabled),
            targets: targets,
            schemes: schemes
        )
    }
}
