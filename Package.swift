// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SudoApiClient",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "SudoApiClient",
            targets: ["SudoApiClient"]),
    ],
    dependencies: [
        // TODO: Replace internal package with published version once released.
        .package(url: "https://github.com/sudoplatform/sudo-logging-ios", from: "2.0.0"),
        .package(url: "https://github.com/sudoplatform/sudo-user-ios", from: "17.0.3"),
        .package(url: "https://github.com/sudoplatform/sudo-config-manager-ios", from: "4.0.0"),
        .package(url: "https://github.com/aws-amplify/aws-sdk-ios-spm", exact: "2.36.7"),
        .package(url: "https://github.com/sudoplatform/aws-mobile-appsync-sdk-ios.git", exact: "3.7.2"),
    ],
    targets: [
        .target(
            name: "SudoApiClient",
            dependencies: [
                .product(name: "AWSAppSync", package: "aws-mobile-appsync-sdk-ios"),
                .product(name: "AWSCore", package: "aws-sdk-ios-spm"),
                .product(name: "SudoLogging", package: "sudo-logging-ios"),
                .product(name: "SudoConfigManager", package: "sudo-config-manager-ios"),
                .product(name: "SudoUser", package: "sudo-user-ios")
            ],
            path: "SudoApiClient/"),
    ]
)

