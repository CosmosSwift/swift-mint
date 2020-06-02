// ===----------------------------------------------------------------------===
//
//  This source file is part of the CosmosSwift open source project.
//
//  KeyPathTests.swift last updated 02/06/2020
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

class KeyPathTests: XCTestCase {
    func testKeyPathStartsWithSlash() {
        XCTAssertNotNil(try? Key(string: "/toto/x:1234"))
        XCTAssertNil(try? Key(string: "toto/x:1234"))
    }

    func testKeyPathContainsUnknownEncoding() {
        XCTAssertNotNil(try? Key(string: "/toto/x:1234"))
        XCTAssertNil(try? Key(string: "/toto/x:tyh"))
    }

    func testUpperCaseHexEncoding() {
        let k0 = try? Key(string: "/toto/x:ABCD")
        print("\(k0!) : \(k0!.path)")
        XCTAssertNotNil(k0)
        let k1 = try? Key(string: "/toto/x:abcd")
        print("\(k1!) : \(k1!.path)")
        XCTAssert(k0 == k1)
    }

    func testEmptyKey() {
        // The only way to get an empty subkey is to get it from the static instance SubKey.empty
        var k = try? Key(string: "/")
        XCTAssertNil(k)
        k = try? Key(string: "//")
        XCTAssertNil(k)
    }

    func testKeyPath() throws {
        var path: Key
        var keys: [SubKey]
        let alphanum = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let hex = "1234567890ABCDEF"

        for _ in 0 ..< 10000 {
            path = []
            keys = []
            for _ in 0 ..< 10 {
                let subKeySize: Int = Int.random(in: 1 ... 20)
                let sk: SubKey
                if Bool.random() {
                    let str = (1 ... subKeySize).reduce("") { (r, _) -> String in
                        r + String(alphanum.randomElement()!)
                    }
                    sk = SubKey(str)!
                } else {
                    let hex = (1 ... subKeySize * 2).reduce("") { (r, _) -> String in
                        r + String(hex.randomElement()!)
                    }
                    sk = SubKey(hex: hex)!
                }
                keys.append(sk)
                path.append(sk)
            }
            let res = try? Key(string: path.path)
            XCTAssertNotNil(res)
            if let res = res {
                for (i, key) in keys.enumerated() {
                    XCTAssert(key == res[i])
                }
            }
        }
    }

    static var allTests = [
        ("testKeyPathStartsWithSlash", testKeyPathStartsWithSlash),
        ("testKeyPathContainsUnknownEncoding", testKeyPathContainsUnknownEncoding),
        ("testUpperCaseHexEncoding", testUpperCaseHexEncoding),
        ("testEmptyKey", testEmptyKey),
        ("testKeyPath", testKeyPath),
    ]
}
