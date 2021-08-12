// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "App",
    platforms: [ .macOS(.v11), .iOS(.v14) ],
    products: [ .library(name: "App", targets: ["App"]) ],
    dependencies: [
        .package(name: "Fair", url: "https://github.com/appfair/Fair.git", .branch("main")),
    ],
    targets: [
        .target(name: "App", dependencies: [ .product(name: "FairApp", package: "Fair") ], resources: [.copy("Bundle")]),
        .testTarget(name: "AppTests", dependencies: [.product(name: "FairApp", package: "Fair")]),
    ]
)

// The following validations are required in order for the package to be integrated by the App Fair

precondition(!package.dependencies.isEmpty, "package must have at least one dependency")
precondition(package.dependencies[0].name == "Fair", "first dependency name must be \"Fair\"")
precondition(package.dependencies[0].url == "https://github.com/appfair/Fair.git" || package.dependencies[0].url == "git@github.com:appfair/Fair.git", "first package dependency must be https://github.com/appfair/Fair.git")

precondition(package.products.count == 1, "package must have exactly one product")
precondition(package.products[0].name == "App", "package product must be named \"App\"")

// validate target names and source paths

precondition(package.targets.count == 2, "package must have exactly two targets named \"App\" and \"AppTests\"")
precondition(package.targets[0].name == "App", "first target must be named \"App\"")
precondition(package.targets[0].path == nil || package.targets[0].path == "Sources", "first target path must be named \"Sources\"")
precondition(package.targets[0].sources == nil, "first target sources must be empty")

precondition(package.targets[1].name == "AppTests", "second target must be named \"AppTests\"")
precondition(package.targets[1].path == nil || package.targets[1].path == "Tests", "second target must be named \"Tests\"")
precondition(package.targets[1].sources == nil, "second target sources must be empty")

precondition(!package.targets[0].dependencies.isEmpty, "package target must have at least one dependency")

// Target.Depencency is opaque and non-equatable, so resort to using the description for validation
precondition(String(describing: package.targets[0].dependencies[0]) == "productItem(name: \"FairApp\", package: Optional(\"Fair\"), condition: nil)", "for package dependency must be FairApp")
precondition(String(describing: package.platforms?.first) == "Optional(PackageDescription.SupportedPlatform(platform: PackageDescription.Platform(name: \"macos\"), version: Optional(\"11.0\")))", "package must support macOS 11")
precondition(String(describing: package.platforms?.last) == "Optional(PackageDescription.SupportedPlatform(platform: PackageDescription.Platform(name: \"ios\"), version: Optional(\"14.0\")))", "package must support iOS 14")


