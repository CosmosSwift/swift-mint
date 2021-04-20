// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "swift-mint",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(name: "Merkle", targets: ["Merkle"]),
    ],
    dependencies: [
        .package(name: "swift-hex-string", url: "https://github.com/CosmosSwift/swift-hex-string.git", from: "1.0.0"),
        .package(name: "swift-crypto", url: "https://github.com/apple/swift-crypto", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .target(
            name: "Merkle",
            dependencies: [
                .product(name: "HexString", package: "swift-hex-string"),
                .product(name: "Crypto", package: "swift-crypto"),
            ]
        ),
        .testTarget(name: "MerkleTests", dependencies: ["Merkle"]),
    ]
)
