// ===----------------------------------------------------------------------===
//
//  This source file is part of the CosmosSwift open source project.
//
//  RFC6962Tests.swift last updated 02/06/2020
//
//  Copyright © 2020 Katalysis B.V. and the CosmosSwift project authors.
//  Licensed under Apache License v2.0
//
//  See LICENSE.txt for license information
//  See CONTRIBUTORS.txt for the list of CosmosSwift project authors
//
//  SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===

@testable import Merkle
import XCTest

class RFC6962Tests: XCTestCase {
    func testRFC6962Hasher() throws {
        let leaf = "L123456".data(using: .utf8)!
        let emptyLeaf = "".data(using: .utf8)!

        let (_, leafHashTrail): ([SimpleProofNode<TMHash>], SimpleProofNode<TMHash>) = trailsFromByteSlices([leaf])
        let (_, emptyLeafTrail): ([SimpleProofNode<TMHash>], SimpleProofNode<TMHash>) = trailsFromByteSlices([emptyLeaf])

        let leafHash = leafHashTrail.hash.data
        let emptyLeafHash = emptyLeafTrail.hash.data

        // Since creating a merkle tree of no leaves is unsupported here, we skip
        // the corresponding trillian test vector.

        // Check that the empty hash is not the same as the hash of an empty leaf.

        // RFC6962 Empty Leaf
        // echo -n 00 | xxd -r -p | sha256sum
        XCTAssertEqual("6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d".toData()!, emptyLeafHash)

        // RFC6962 Leaf
        // echo -n 004C313233343536 | xxd -r -p | sha256sum
        XCTAssertEqual("395aa064aa4c29f7010acfe3f25db9485bbd4b91897b6ad7ad547639252b4d56".toData()!, leafHash)

        // RFC6962 Node
        // echo -n 014E3132334E343536 | xxd -r -p | sha256sum
        let left = TMHash(value: [UInt8]("N123".data(using: .utf8)!))
        let right = TMHash(value: [UInt8]("N456".data(using: .utf8)!))
        let nodeHash = Data(TMHash.innerHash(left, right).value)
        XCTAssertEqual("aa217fe888e47007fa15edab33c2b492a722cb106c64667fc2b044444de66bbb".toData()!, nodeHash)
    }

    func testRFC6962HasherCollisions() throws {
        // Check that different leaves have different hashes.
        let leaf1 = "Hello".data(using: .utf8)!
        let leaf2 = "World".data(using: .utf8)!

        let (_, leafHashTrail1): ([SimpleProofNode<TMHash>], SimpleProofNode<TMHash>) = trailsFromByteSlices([leaf1])
        let (_, leafHashTrail2): ([SimpleProofNode<TMHash>], SimpleProofNode<TMHash>) = trailsFromByteSlices([leaf2])

        let hash1 = leafHashTrail1.hash.data
        let hash2 = leafHashTrail2.hash.data

        XCTAssert(hash1 != hash2, "leaf hashes should differ, but both are \(hash1)")

        // Compute an intermediate subtree hash.
        let (_, subHash1Trail): ([SimpleProofNode<TMHash>], SimpleProofNode<TMHash>) = trailsFromByteSlices([hash1, hash2])
        let subHash1 = subHash1Trail.hash.data
        // Check that this is not the same as a leaf hash of their concatenation.
        let preimage = leaf1 + leaf2
        let (_, forgedHashTrail): ([SimpleProofNode<TMHash>], SimpleProofNode<TMHash>) = trailsFromByteSlices([preimage])
        let forgedHash = forgedHashTrail.hash.data
        XCTAssert(subHash1 != forgedHash, "hasher is not second-preimage resistant")

        // Swap the order of nodes and check that the hash is different.
        let (_, subHash2Trail): ([SimpleProofNode<TMHash>], SimpleProofNode<TMHash>) = trailsFromByteSlices([hash2, hash1])
        let subHash2 = subHash2Trail.hash.data
        XCTAssert(subHash1 != subHash2, "subtree hash does not depend on the order of leaves")
    }

    static var allTests = [
        ("testRFC6962Hasher", testRFC6962Hasher),
        ("testRFC6962HasherCollisions", testRFC6962HasherCollisions),
    ]
}
