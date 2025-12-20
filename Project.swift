import ProjectDescription

let settings = Settings.settings(
  base: [
    "SWIFT_VERSION": "6.0"
  ]
)

let macOSDeploymentTarget = "13.0"
let iOSDeploymentTarget = "18.0"

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
  ]
)
