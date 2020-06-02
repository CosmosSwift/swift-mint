// ===----------------------------------------------------------------------===
//
//  This source file is part of the CosmosSwift open source project.
//
//  SimpleMapTests.swift last updated 02/06/2020
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

import Merkle
import XCTest

class SimpleMapTests: XCTestCase {
    func testSimpleMap() throws {
        var sm1 = SimpleMap<TMHash, SimpleCodec>(["key1": Data("value1".utf8)])
        XCTAssertEqual("a44d3cc7daba1a4600b00a2434b30f8b970652169810d6dfa9fb1793a2189324".toData()!, sm1.hash()?.data)

        var sm2 = SimpleMap<TMHash, SimpleCodec>(["key1": Data("value2".utf8)])
        XCTAssertEqual("0638e99b3445caec9d95c05e1a3fc1487b4ddec6a952ff337080360b0dcc078c".toData()!, sm2.hash()?.data)

        // swap order with 2 keys
        var sm3 = SimpleMap<TMHash, SimpleCodec>(["key1": Data("value1".utf8), "key2": Data("value2".utf8)])
        XCTAssertEqual("8fd19b19e7bb3f2b3ee0574027d8a5a4cec370464ea2db2fbfa5c7d35bb0cff3".toData()!, sm3.hash()?.data)

        var sm4 = SimpleMap<TMHash, SimpleCodec>(["key2": Data("value2".utf8), "key1": Data("value1".utf8)])
        XCTAssertEqual("8fd19b19e7bb3f2b3ee0574027d8a5a4cec370464ea2db2fbfa5c7d35bb0cff3".toData()!, sm4.hash()?.data)

        // swap order with 3 keys
        var sm5 = SimpleMap<TMHash, SimpleCodec>(["key1": Data("value1".utf8), "key2": Data("value2".utf8), "key3": Data("value3".utf8)])
        XCTAssertEqual("1dd674ec6782a0d586a903c9c63326a41cbe56b3bba33ed6ff5b527af6efb3dc".toData()!, sm5.hash()?.data)

        var sm6 = SimpleMap<TMHash, SimpleCodec>(["key1": Data("value1".utf8), "key3": Data("value3".utf8), "key2": Data("value2".utf8)])
        XCTAssertEqual("1dd674ec6782a0d586a903c9c63326a41cbe56b3bba33ed6ff5b527af6efb3dc".toData()!, sm6.hash()?.data)
    }

    static var allTests = [
        ("testSimpleMap", testSimpleMap),
    ]
}
