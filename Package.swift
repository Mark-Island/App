// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Mark-Island",
    defaultLocalization: "en",
    platforms: [ .macOS(.v11), .iOS(.v14) ],
    products: [ .library(name: "App", targets: ["App"]) ],
    dependencies: [
        .package(name: "Fair", url: "https://github.com/appfair/Fair.git", .branch("main")),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.12.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [ .product(name: "FairApp", package: "Fair"), .product(name: "SQLite", package: "SQLite.swift"), ], resources: [.process("Resources"), .copy("Bundle")]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)

