# CosmosSwift

![Swift5.2+](https://img.shields.io/badge/Swift-5.2+-blue.svg)
![platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20linux-orange.svg)

Build blockchain application states in Swift on top of the Tendermint consensus. This can be combined with Swift ABCI, which allows to build ABCI Servers in Swift to communicate with a Tendermint consensus.

This is work in progress.

The current focus is to provide the structures required to store the state, namely Merkle trees (in this repository) and iAVL+ trees (in [https://github.com/cosmosswift/swift-iavlplus](https://github.com/cosmosswift/swift-iavlplus/)).

We are using the Go Tendermint codebase as a starting point, and implementing the Swift code in a Swifty way.


## Installation

Requires Swift 5.2.x, on MacOS or a variant of Linux with the Swift 5.2.x toolchain installed.

``` bash
git clone https://github.com/cosmosswift/swift-mint.git
cd cosmosswift
swift build
```

In your `Package.swift` file, add the repository as a dependency as such:
``` swift
import PackageDescription

let package = Package(
    name: "MyCosmosSwiftApp",
    products: [
        .executable(name: "MyCosmosSwiftApp", targets: ["MyCosmosSwiftApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/cosmosswift/swift-mint.git", from: "0.3.0"),
    ],
    targets: [
        .target(name: "MyCosmosSwiftApp", dependencies: ["Merkle"]),
    ]
)
```

Other than use the `ProofOperatorProtocol`, there is not much practical use to this repo as of now.

In the coming milestone, we will add the following capabilities:
-
-
-


## Getting Started

0. `import CosmosSwift`


1. Compile and run

## Development

Compile:
1. run `swift build`

## Documentation

The docs for the latest tagged release are always available at [https://katalysis.gitlab.io/open-source/cosmosswift/](https://katalysis.gitlab.io/open-source/cosmosswift/).

## Questions

For bugs or feature requests, file a new [issue](https://github.com/cosmosswift/swift-mint/issues).

For all other support requests, please email [opensource@katalysis.io](mailto:opensource@katalysis.io).

## Changelog

[SemVer](https://semver.org/) changes are documented for each release on the [releases page](https://github.com/cosmosswift/swift-mint/-/releases).

## Contributing

Check out [CONTRIBUTING.md](https://github.com/cosmosswift/swift-mint/blob/master/CONTRIBUTING.md) for more information on how to help with **CosmosSwift**.

## Contributors

Check out [CONTRIBUTORS.txt](https://github.com/cosmosswift/swift-mint/blob/master/CONTRIBUTORS.txt) to see the full list. This list is updated for each release.
