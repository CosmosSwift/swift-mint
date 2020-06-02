// ===----------------------------------------------------------------------===
//
//  This source file is part of the CosmosSwift open source project.
//
//  SimpleProofTests.swift last updated 02/06/2020
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

class SimpleProofTests: XCTestCase {
    func testSimpleProofCreation() throws {
        let items: [Data] = [
            "apple".data(using: .utf8)!,
            "watermelon".data(using: .utf8)!,
            "kiwi".data(using: .utf8)!,
        ]

        let (root, proofs): (TMHash, [SimpleProof]) = try simpleProofsFromByteSlices(items)

        print("Root: \(root), Proofs: \(proofs)")

        // TODO: should test this properly, ie expected proof and roots (check with go code)

        // Below is current output
        /*
                    Root: Hash<C10121CC6F05EAA88CD6F15A9DD04721B6E9CF21948754B965F68B8A307F60A7>, Proofs: [SimpleProof {
                    total:    3
                    index:    0
                    leafHash: Hash<03CFD2A81065D4F0B9CA6DA0D8D09B25DB0E2C5E0CC3914B2EA8C6E0FD303E2A>
                    aunts:    [Hash<0660BD76705D61189D66ECF14D3866E6B4EFDD9700D3AB4AB74D328BA2C003CC>, Hash<30FDC7E2822CEAAE6961BF20D85D13F68AE76421C1758487EA090E54C732BC50>]
                    }, SimpleProof {
                    total:    3
                    index:    1
                    leafHash: Hash<0660BD76705D61189D66ECF14D3866E6B4EFDD9700D3AB4AB74D328BA2C003CC>
                    aunts:    [Hash<03CFD2A81065D4F0B9CA6DA0D8D09B25DB0E2C5E0CC3914B2EA8C6E0FD303E2A>, Hash<30FDC7E2822CEAAE6961BF20D85D13F68AE76421C1758487EA090E54C732BC50>]
                    }, SimpleProof {
                    total:    3
                    index:    2
                    leafHash: Hash<30FDC7E2822CEAAE6961BF20D85D13F68AE76421C1758487EA090E54C732BC50>
                    aunts:    [Hash<BCCC87D9C12F7FFFE45A2DBE003F2FDCE5A2359BD195655D6B68A0BF481F7E08>]
                    }]
         */
    }

    func testValidateBasics() throws {
        XCTAssertNoThrow(try SimpleProof<TMHash>(total: 1, index: 0, leafHash: TMHash(value: []), aunts: []))
        XCTAssertThrowsError(try SimpleProof<TMHash>(total: 0, index: 0, leafHash: TMHash(value: []), aunts: []))
        XCTAssertThrowsError(try SimpleProof<TMHash>(total: -1, index: 0, leafHash: TMHash(value: []), aunts: []))
        XCTAssertThrowsError(try SimpleProof<TMHash>(total: 1, index: 2, leafHash: TMHash(value: []), aunts: []))
        XCTAssertThrowsError(try SimpleProof<TMHash>(total: 1, index: -1, leafHash: TMHash(value: []), aunts: []))
        XCTAssertThrowsError(try SimpleProof<TMHash>(total: 1, index: 0, leafHash: TMHash(value: []), aunts: [TMHash](repeating: TMHash(value: []), count: MAX_AUNTS + 1)))
    }

    static var allTests = [
        ("testSimpleProofCreation", testSimpleProofCreation),
        ("testValidateBasics", testValidateBasics),
    ]
}
