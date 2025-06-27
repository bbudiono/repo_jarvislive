// swift-tools-version: 5.7
// SANDBOX FILE: For iOS testing/development. See .cursorrules.

import PackageDescription

let package = Package(
    name: "JarvisLiveSandbox",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .executable(name: "JarvisLiveSandbox", targets: ["JarvisLiveSandbox"]),
        .library(name: "JarvisLiveCore", targets: ["JarvisLiveCore"])
    ],
    dependencies: [
        // Keychain access for secure storage
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", .upToNextMajor(from: "4.2.2")),
        // Snapshot testing for automated UI regression detection
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", .upToNextMajor(from: "1.15.1"))
    ],
    targets: [
        .executableTarget(
            name: "JarvisLiveSandbox",
            dependencies: [
                "JarvisLiveCore",
                .product(name: "KeychainAccess", package: "KeychainAccess")
            ]
        ),
        .target(
            name: "JarvisLiveCore",
            dependencies: [
                .product(name: "KeychainAccess", package: "KeychainAccess")
            ]
        ),
        .testTarget(
            name: "JarvisLiveSandboxTests",
            dependencies: [
                "JarvisLiveSandbox", 
                "JarvisLiveCore",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        ),
    ]
)
