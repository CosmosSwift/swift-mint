// ===----------------------------------------------------------------------===
//
//  This source file is part of the CosmosSwift open source project.
//
//  CoderType.swift last updated 02/06/2020
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

import Foundation

// TODO: implement using Codable and use swift-amino as implementation
public protocol CoderType {
    static func encode(_ data: Data) -> Data

    static func mustMarshalBinaryLengthPrefixed<ProofOperator: ProofOperatorProtocol>(_ pop: ProofOperator) -> Data
}

public struct SimpleCodec: CoderType {
    public static func encode(_ data: Data) -> Data {
        var res = Data()
        let varint = varintEncode(data.count)
        res.append(contentsOf: varint)
        res.append(contentsOf: data)
        return res
    }

    public static func mustMarshalBinaryLengthPrefixed<ProofOperator: ProofOperatorProtocol>(_: ProofOperator) -> Data {
        // TODO: implement properly
        fatalError("Not implemented")
        // Data()
    }
}

// ZigZag encoding
internal func zigZagEncode<T: SignedInteger>(_ n: T) -> UInt {
    let num = Int64(n) // FIX: there is a problem here, needs to be checked
    let size = MemoryLayout<UInt>.size
    return UInt((num << 1) ^ (num >> (size * 8 - 1)))
}

// ZigZag decoding
internal func zigZagDecode<T: UnsignedInteger>(_ n: T) -> Int {
    switch n % 2 {
    case 0:
        return Int(n >> 1)
    default:
        return -Int((n + 1) >> 1)
    }
}

// VarintEncode
internal func varintEncode<T: FixedWidthInteger>(_ n: T) -> [UInt8] {
    var u = UInt64(n)
    var a = [UInt8]()
    while u != 0 {
        a.append(UInt8(u % 128))
        u = u >> 7
    }
    if a.count == 0 { a.append(0x0) }
    for i in 0 ..< a.count - 1 {
        a[i] = a[i] ^ (1 << 7)
    }
    return a
}

// VarintDecode
internal func varintDecode(_ array: [UInt8]) -> UInt64 {
    assert(array.count < 11)
    var res: UInt64 = 0
    for i in 0 ..< array.count {
        res = res << 7 + UInt64(array[array.count - i - 1] & 127)
    }
    return res
}
