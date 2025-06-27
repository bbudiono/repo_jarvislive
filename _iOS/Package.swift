// swift-tools-version: 5.7
// Jarvis Live iOS Package Dependencies

import PackageDescription

let package = Package(
    name: "JarvisLive",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "JarvisLive",
            targets: ["JarvisLive"]
        ),
    ],
    dependencies: [
        // Keychain access for secure storage
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", .upToNextMajor(from: "4.2.2")),
        // Snapshot testing for automated UI regression detection
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", .upToNextMajor(from: "1.15.1"))
    ],
    targets: [
        .target(
            name: "JarvisLive",
            dependencies: [
                .product(name: "KeychainAccess", package: "KeychainAccess")
            ],
            path: "JarvisLive/Sources"
        ),
        .testTarget(
            name: "JarvisLiveTests",
            dependencies: [
                "JarvisLive",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "JarvisLive/Tests"
        ),
    ]
)