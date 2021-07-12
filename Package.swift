// swift-tools-version:5.3
/**
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import PackageDescription

let package = Package(
    name: "App",
    platforms: [
        .macOS(.v11), .iOS(.v14), .tvOS(.v14), .watchOS(.v7)
    ],
    products: [
        .library(name: "App", targets: ["App"]),
        .executable(name: "apptool", targets: ["Tool"]),
    ],
    dependencies: [
        .package(url: "https://github.com/appfair/Fair.git", .branch("main"))
    ]
    + externalDependencies().map(\.package),
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "FairApp", package: "Fair")
        ] + externalDependencies().flatMap(\.targets),
            resources: [.copy("Bundle")]),
        .target(name: "Tool", dependencies: [
            .product(name: "FairCore", package: "Fair")
        ]),
        .testTarget(name: "AppTests", dependencies: [
            "App"
        ]),
    ]
)

// Everything above this line must remain unmodified.

/// Return an array of tuples for each of the app's dependencies: `(Package.Dependency, [Target.Dependency])`
func externalDependencies() -> [(package: PackageDescription.Package.Dependency, targets: [PackageDescription.Target.Dependency])] {
    [
        //(.package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.4.0")), [.product(name: "Logging", package: "swift-log")]),
        //(.package(url: "https://github.com/apple/swift-crypto.git", .upToNextMajor(from: "1.0.0")), [.product(name: "Crypto", package: "swift-crypto")]),
        //(.package(url: "https://github.com/apple/swift-metrics.git", .upToNextMajor(from: "2.1.0")), [.product(name: "CoreMetrics", package: "swift-metrics"), .product(name: "Metrics", package: "swift-metrics")]),
    ]
}

