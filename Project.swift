import ProjectDescription

let settings = Settings.settings(
  base: [
    "SWIFT_VERSION": "6.0"
  ]
)

let macOSDeploymentTarget = "13.0"
let iOSDeploymentTarget = "16.0"

let project = Project(
  name: "RCKit",
  options: .options(automaticSchemesOptions: .disabled),
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
      ]
    ),
    .target(
      name: "RCKitDemo",
      destinations: .iOS,
      product: .app,
      bundleId: "dev.rocry.RCKitDemo",
      deploymentTargets: .iOS(iOSDeploymentTarget),
      infoPlist: .extendingDefault(
        with: [
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
        .xcframework(
          path: "Dependencies/NSLoggerSwift.xcframework",
          condition: .when([.ios])
        ),
      ]
    ),
    .target(
      name: "RCKitDemoMac",
      destinations: .macOS,
      product: .app,
      bundleId: "dev.rocry.RCKitDemoMac",
      deploymentTargets: .macOS(macOSDeploymentTarget),
      infoPlist: .default,
      sources: ["RCKitDemo/Sources/**"],
      dependencies: [
        .target(name: "RCKit"),
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
      name: "RCKitDemoMac",
      shared: true,
      buildAction: .buildAction(targets: [.target("RCKitDemoMac")]),
      runAction: .runAction(
        configuration: .debug,
        executable: .target("RCKitDemoMac"),
        expandVariableFromTarget: .target("RCKitDemoMac")
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
  ]
)
