// ===----------------------------------------------------------------------===
//
//  This source file is part of the CosmosSwift open source project.
//
//  ProofTests.swift last updated 02/06/2020
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

// Expects given input, produces given output.
// Like the game dominos.
struct DominoOp: ProofOperatorProtocol {
    var key: Data // unexported, may be empty

    var type: String = "test:domino"

    var data: Data?
    let output: Data

    public init(_ key: String, _ input: String, _ output: String) {
        self.key = SubKey(key)?.data() ?? Data()
        data = input.data(using: .utf8)!
        self.output = output.data(using: .utf8)!
    }

    public func run(_ data: [Data]) throws -> [Data] {
        guard data.count == 1 else { throw CosmosSwiftError.general("expected input of length 1") }

        if data[0] != self.data { throw CosmosSwiftError.general("expected input \(self.data), got \(data[0])") }

        return [output]
    }
}

class ProofTests: XCTestCase {
    func testWithEmptyKey() throws {
        // TODO: According to the go test (tendermint/tendermint/crypto/merkle/), it is not expected to throw.
        // However, from the Go implementation, this seems to be expected to
        // throw. The current Swift implementation does throw, because we do not
        // expect subkeys to be ever empty as they represent a unique entry in
        // the  tree. Handling such a case would lead to slower and more complex
        // code, so this is left as is for now.

        let ops = [
            DominoOp("KEY1", "INPUT1", "INPUT2"),
            DominoOp("KEY2", "INPUT2", "INPUT3"),
            DominoOp("", "INPUT3", "INPUT4"),
            DominoOp("KEY4", "INPUT4", "OUTPUT4"),
        ]

        let popz = ops
        let hash1 = TMHash.hash(data: [UInt8]("OUTPUT4".data(using: .utf8)!))
        let key1 = try Key(string: "/KEY4/KEY2/KEY1").map { $0.data() }
        let args1 = "INPUT1".data(using: .utf8)!
        XCTAssertThrowsError(try popz.verify(root: hash1, key: key1, args: [args1]))
        XCTAssertThrowsError(try popz.verifyValue(root: hash1, key: key1, value: args1))
    }

    func testKey() throws {
        let ops = [
            DominoOp("KEY1", "INPUT1", "INPUT2"),
            DominoOp("KEY2", "INPUT2", "INPUT3"),
            DominoOp("KEY3", "INPUT3", "INPUT4"),
            DominoOp("KEY4", "INPUT4", "OUTPUT4"),
        ]

        // Good
        let popz = ops
        let hash1 = TMHash.hash(data: [UInt8]("OUTPUT4".data(using: .utf8)!))
        let key1 = try Key(string: "/KEY4/KEY3/KEY2/KEY1").map { $0.data() }
        let args1 = "INPUT1".data(using: .utf8)!
        XCTAssertNoThrow(try popz.verify(root: hash1, key: key1, args: [args1]))
        XCTAssertNoThrow(try popz.verifyValue(root: hash1, key: key1, value: args1))
    }

    func testKeyBadInput() throws {
        let ops = [
            DominoOp("KEY1", "INPUT1", "INPUT2"),
            DominoOp("KEY2", "INPUT2", "INPUT3"),
            DominoOp("KEY3", "INPUT3", "INPUT4"),
            DominoOp("KEY4", "INPUT4", "OUTPUT4"),
        ]

        let popz = ops
        let hash1 = TMHash.hash(data: [UInt8]("OUTPUT4".data(using: .utf8)!))
        let key1 = try Key(string: "/KEY4/KEY3/KEY2/KEY1").map { $0.data() }
        let args1 = "INPUT1_WRONG".data(using: .utf8)!
        XCTAssertThrowsError(try popz.verify(root: hash1, key: key1, args: [args1]))
        XCTAssertThrowsError(try popz.verifyValue(root: hash1, key: key1, value: args1))
    }

    func testKeyBadKey1() throws {
        let ops = [
            DominoOp("KEY1", "INPUT1", "INPUT2"),
            DominoOp("KEY2", "INPUT2", "INPUT3"),
            DominoOp("KEY3", "INPUT3", "INPUT4"),
            DominoOp("KEY4", "INPUT4", "OUTPUT4"),
        ]

        let popz = ops
        let hash1 = TMHash.hash(data: [UInt8]("OUTPUT4".data(using: .utf8)!))
        let key1 = try Key(string: "/KEY3/KEY3/KEY2/KEY1").map { $0.data() }
        let args1 = "INPUT1".data(using: .utf8)!
        XCTAssertThrowsError(try popz.verify(root: hash1, key: key1, args: [args1]))
        XCTAssertThrowsError(try popz.verifyValue(root: hash1, key: key1, value: args1))
    }

    func testKeyBadKey2() throws {
        XCTAssertThrowsError(try Key(string: "KEY4/KEY3/KEY2/KEY1"))
    }

    func testKeyBadKey3() throws {
        XCTAssertThrowsError(try Key(string: "/KEY4/KEY3/KEY2/KEY1/"))
    }

    func testKeyBadKey4() throws {
        XCTAssertThrowsError(try Key(string: "//KEY4/KEY3/KEY2/KEY1"))
    }

    func testKeyBadKey5() throws {
        let ops = [
            DominoOp("KEY1", "INPUT1", "INPUT2"),
            DominoOp("KEY2", "INPUT2", "INPUT3"),
            DominoOp("KEY3", "INPUT3", "INPUT4"),
            DominoOp("KEY4", "INPUT4", "OUTPUT4"),
        ]

        let popz = ops
        let hash1 = TMHash.hash(data: [UInt8]("OUTPUT4".data(using: .utf8)!))
        let key1 = try Key(string: "/KEY3/KEY2/KEY1").map { $0.data() }
        let args1 = "INPUT1".data(using: .utf8)!
        XCTAssertThrowsError(try popz.verify(root: hash1, key: key1, args: [args1]))
        XCTAssertThrowsError(try popz.verifyValue(root: hash1, key: key1, value: args1))
    }

    func testKeyBadOutput1() throws {
        let ops = [
            DominoOp("KEY1", "INPUT1", "INPUT2"),
            DominoOp("KEY2", "INPUT2", "INPUT3"),
            DominoOp("KEY3", "INPUT3", "INPUT4"),
            DominoOp("KEY4", "INPUT4", "OUTPUT4"),
        ]

        let popz = ops
        let hash1 = TMHash.hash(data: [UInt8]("OUTPUT4_WRONG".data(using: .utf8)!))
        let key1 = try Key(string: "/KEY4/KEY3/KEY2/KEY1").map { $0.data() }
        let args1 = "INPUT1".data(using: .utf8)!
        XCTAssertThrowsError(try popz.verify(root: hash1, key: key1, args: [args1]))
        XCTAssertThrowsError(try popz.verifyValue(root: hash1, key: key1, value: args1))
    }

    func testKeyBadOutput2() throws {
        let ops = [
            DominoOp("KEY1", "INPUT1", "INPUT2"),
            DominoOp("KEY2", "INPUT2", "INPUT3"),
            DominoOp("KEY3", "INPUT3", "INPUT4"),
            DominoOp("KEY4", "INPUT4", "OUTPUT4"),
        ]

        let popz = ops
        let hash1 = TMHash.hash(data: [UInt8]("".data(using: .utf8)!))
        let key1 = try Key(string: "/KEY4/KEY3/KEY2/KEY1").map { $0.data() }
        let args1 = "INPUT1".data(using: .utf8)!
        XCTAssertThrowsError(try popz.verify(root: hash1, key: key1, args: [args1]))
        XCTAssertThrowsError(try popz.verifyValue(root: hash1, key: key1, value: args1))
    }

    func testKeyBadOps1() throws {
        let ops = [
            DominoOp("KEY1", "INPUT1", "INPUT2"),
            DominoOp("KEY2", "INPUT2", "INPUT3"),
            DominoOp("KEY3", "INPUT3", "INPUT4"),
            DominoOp("KEY4", "INPUT4", "OUTPUT4"),
        ]

        let popz = [ops[0], ops[1], ops[3]]
        let hash1 = TMHash.hash(data: [UInt8]("OUTPUT4".data(using: .utf8)!))
        let key1 = try Key(string: "/KEY4/KEY3/KEY2/KEY1").map { $0.data() }
        let args1 = "INPUT1".data(using: .utf8)!
        XCTAssertThrowsError(try popz.verify(root: hash1, key: key1, args: [args1]))
        XCTAssertThrowsError(try popz.verifyValue(root: hash1, key: key1, value: args1))
    }

    func testKeyBadOps2() throws {
        let ops = [
            DominoOp("KEY1", "INPUT1", "INPUT2"),
            DominoOp("KEY2", "INPUT2", "INPUT3"),
            DominoOp("KEY3", "INPUT3", "INPUT4"),
            DominoOp("KEY4", "INPUT4", "OUTPUT4"),
        ]

        let popz: [DominoOp] = ops.reversed()
        let hash1 = TMHash.hash(data: [UInt8]("OUTPUT4".data(using: .utf8)!))
        let key1 = try Key(string: "/KEY4/KEY3/KEY2/KEY1").map { $0.data() }
        let args1 = "INPUT1".data(using: .utf8)!
        XCTAssertThrowsError(try popz.verify(root: hash1, key: key1, args: [args1]))
        XCTAssertThrowsError(try popz.verifyValue(root: hash1, key: key1, value: args1))
    }

    func testKeyBadOps3() throws {
        let popz: [DominoOp] = []
        let hash1 = TMHash.hash(data: [UInt8]("OUTPUT4".data(using: .utf8)!))
        let key1 = try Key(string: "/KEY4/KEY3/KEY2/KEY1").map { $0.data() }
        let args1 = "INPUT1".data(using: .utf8)!
        XCTAssertThrowsError(try popz.verify(root: hash1, key: key1, args: [args1]))
        XCTAssertThrowsError(try popz.verifyValue(root: hash1, key: key1, value: args1))
    }

    static var allTests = [
        ("testWithEmptyKey", testWithEmptyKey),
        ("testKey", testKey),
        ("testKeyBadInput", testKeyBadInput),
        ("testKeyBadKey1", testKeyBadKey1),
        ("testKeyBadKey2", testKeyBadKey2),
        ("testKeyBadKey3", testKeyBadKey3),
        ("testKeyBadKey4", testKeyBadKey4),
        ("testKeyBadKey5", testKeyBadKey5),
        ("testKeyBadOutput1", testKeyBadOutput1),
        ("testKeyBadOutput2", testKeyBadOutput2),
        ("testKeyBadOps1", testKeyBadOps1),
        ("testKeyBadOps2", testKeyBadOps2),
        ("testKeyBadOps3", testKeyBadOps3),
    ]
}
