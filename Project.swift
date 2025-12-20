import ProjectDescription

let settings = Settings.settings(
  base: [
    "SWIFT_VERSION": "6.0"
  ]
)

let project = Project(
  name: "RCKit",
  settings: settings,
  targets: [
    .target(
      name: "RCKit",
      destinations: .iOS,
      product: .framework,
      bundleId: "dev.rocry.RCKit",
      infoPlist: .default,
      sources: ["RCKit/Sources/**"],
      dependencies: [
        .external(name: "Logging")
      ]
    ),
    .target(
      name: "RCKitDemo",
      destinations: .iOS,
      product: .app,
      bundleId: "dev.rocry.RCKitDemo",
      infoPlist: .extendingDefault(
        with: [
          "UILaunchScreen": [
            "UIColorName": "",
            "UIImageName": "",
          ],
        ]
      ),
      sources: ["RCKitDemo/Sources/**"],
      resources: ["RCKitDemo/Resources/**"],
      dependencies: [.target(name: "RCKit")]
    ),
    .target(
      name: "RCKitTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "dev.rocry.RCKitTests",
      infoPlist: .default,
      sources: ["RCKit/Tests/**"],
      dependencies: [.target(name: "RCKit")]
    ),
  ]
)
