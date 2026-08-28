// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MenuBarShelf",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "MenuBarShelfCore", targets: ["MenuBarShelfCore"]),
        .executable(name: "MenuBarShelf", targets: ["MenuBarShelf"]),
        .executable(name: "MenuBarShelfCoreChecks", targets: ["MenuBarShelfCoreChecks"])
    ],
    targets: [
        .target(name: "MenuBarShelfCore"),
        .executableTarget(
            name: "MenuBarShelf",
            dependencies: ["MenuBarShelfCore"]
        ),
        .executableTarget(
            name: "MenuBarShelfCoreChecks",
            dependencies: ["MenuBarShelfCore"]
        )
    ]
)
