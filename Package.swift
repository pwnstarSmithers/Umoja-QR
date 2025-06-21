// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QRCodeSDK",
    platforms: [
        .iOS(.v12),
        .macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "QRCodeSDK",
            targets: ["QRCodeSDK"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        .target(
            name: "QRCodeSDK",
            dependencies: [],
            path: "Sources/QRCodeSDK"
        ),
        .testTarget(
            name: "QRCodeSDKTests",
            dependencies: ["QRCodeSDK"],
            path: "Tests",
            exclude: [
                "README.md",
                "MISSING_EDGE_CASES_ANALYSIS.md", 
                "SECURITY_INTEGRATION_TESTS_SUMMARY.md"
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
) 