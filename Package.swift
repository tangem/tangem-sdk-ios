// swift-tools-version:6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TangemSdk",
    defaultLocalization: "en",
    platforms: [
        .iOS("16.4"),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TangemSdk",
            targets: [
                "TangemSdk",
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", exact: "1.9.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TangemSdk",
            dependencies: [
                "TangemSdk_secp256k1",
                "Bls_Signature",
                "CryptoSwift",
            ],
            path: "TangemSdk/TangemSdk",
            exclude: [
                "Crypto/secp256k1",
                "Frameworks",
                "module.modulemap",
                "TangemSdk.h",
            ],
            resources: [
                .process("Common/Localization/Resources"),
                .copy("Haptics"),
                .copy("Crypto/BIP39/Wordlists/english.txt"),
                .copy("PrivacyInfo.xcprivacy"),
                .process("Assets"),
            ]
        ),
        .target(
            name: "TangemSdk_secp256k1",
            path: "TangemSdk/TangemSdk/Crypto/secp256k1",
            cSettings: [
                .disableWarning("shorten-64-to-32"), // Vendored libsecp256k1 narrows 64-bit values to 32 bits by design
            ]
        ),
        .binaryTarget(
            name: "Bls_Signature",
            path: "TangemSdk/TangemSdk/Frameworks/Bls_Signature.xcframework"
        ),
        .testTarget(
            name: "TangemSdkTests",
            dependencies: [
                "TangemSdk",
                "CryptoSwift",
            ],
            path: "TangemSdk/TangemSdkTests",
            resources: [
                .copy("Jsons"),
            ]
        ),
    ],
    // [REDACTED_TODO_COMMENT]
    swiftLanguageModes: [.v5]
)
