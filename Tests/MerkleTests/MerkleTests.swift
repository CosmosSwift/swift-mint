// ===----------------------------------------------------------------------===
//
//  This source file is part of the CosmosSwift open source project.
//
//  MerkleTests.swift last updated 02/06/2020
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

extension TMHash {
    static func random() -> TMHash {
        var array: [UInt8] = []
        for _ in 0 ..< TMHash.size {
            array.append(UInt8.random(in: 0 ... 255))
        }
        return TMHash(value: array)
    }
}

final class MerkleTests: XCTestCase {
    func testSimpleProof() throws {
        let total = 100

        var items: [Data] = []
        for _ in 0 ..< total {
            items.append(Data(TMHash.random().value))
        }

        let rootHash1: TMHash? = simpleHashFromByteSlices(items)
        let (rootHash2, proofs): (TMHash, [SimpleProof]) = try simpleProofsFromByteSlices(items)

        XCTAssert(rootHash1 == rootHash2, "Unmatched root hashes: \(String(describing: rootHash1)) vs \(rootHash2)")

        // For each item, check the trail.
        for (i, item) in items.enumerated() {
            let proof = proofs[i]

            // Check total/index
            XCTAssert(proof.index == i, "Unmatched indicies: \(proof.index) vs \(i)")
            XCTAssert(proof.total == total, "Unmatched totals: \(proof.total) vs \(total)")

            // Verify success
            XCTAssertNoThrow(try proof.verify(rootHash1!, item), "Verification failed") // Verification failed

//
//            // Trail too long should make it fail
//            var proof1 = proof
//            proof1.addAunt()
//            XCTAssertThrowsError(try proof1.verify(rootHash1!, item), "Expected verification to fail for trail length too long")
//
//            var proof2 = proof
//            proof2.addAunt()            // Trail too short should make it fail
//            XCTAssertThrowsError(try proof2.verify(rootHash1!, item), "Expected verification to fail for trail length too short")
//
//            var proof3 = proof
//            proof3.perturbRootHash()
//            // Mutating the itemHash should make it fail.
//            XCTAssertThrowsError(try proof3.verify(rootHash1!, item),  "Expected verification to fail for mutated root hash")
//
//            var proof4 = proof
//            proof4.perturbItem()
//            // Mutating the rootHash should make it fail.
//            XCTAssertThrowsError(try proof4.verify(rootHash1!, item), "Expected verification to fail for mutated leaf hash")
        }
    }

    func testSimpleHashAlternatives() {
        let total = 1000

        var items: [Data] = []
        for _ in 0 ..< total {
            items.append(Data(TMHash.random().value))
        }

        let rootHash1: TMHash? = simpleHashFromByteSlicesRecursive(items)
        let rootHash2: TMHash? = simpleHashFromByteSlicesIterative(items)

        XCTAssert(rootHash1 == rootHash2, "Unmatched root hashes: \(String(describing: rootHash1)) vs \(String(describing: rootHash2))")
    }

    func testBenchmarkSimpleHashRecursive() {
        let N = 1000 // 000

        let total = 100

        var items: [Data] = []
        for _ in 0 ..< total {
            items.append(Data(TMHash.random().value))
        }

        measure { // recursive
            for _ in 0 ..< N {
                let _: TMHash? = simpleHashFromByteSlicesRecursive(items)
            }
        }
    }

    func testBenchmarkSimpleHashIterative() {
        let N = 1000 // 000

        let total = 100

        var items: [Data] = []
        for _ in 0 ..< total {
            items.append(Data(TMHash.random().value))
        }

        measure { // iterative
            for _ in 0 ..< N {
                let _: TMHash? = simpleHashFromByteSlicesIterative(items)
            }
        }
    }

    func testGetSplitPoint() throws {
        XCTAssertThrowsError(try getSplitPoint(0))
        let test: [(Int, Int?)] = [
            (1, 0),
            (2, 1),
            (3, 2),
            (4, 2),
            (5, 4),
            (10, 8),
            (20, 16),
            (100, 64),
            (255, 128),
            (256, 128),
            (257, 256),
        ]
        for (len, expected) in test {
            XCTAssertEqual(expected, try getSplitPoint(len))
        }
    }

    static var allTests = [
        ("testSimpleProof", testSimpleProof),
        ("testSimpleHashAlternatives", testSimpleHashAlternatives),
        ("testBenchmarkSimpleHashRecursive", testBenchmarkSimpleHashRecursive),
        ("testBenchmarkSimpleHashIterative", testBenchmarkSimpleHashIterative),
        ("testGetSplitPoint", testGetSplitPoint),
    ]
}
