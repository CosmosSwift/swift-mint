// ===----------------------------------------------------------------------===
//
//  This source file is part of the CosmosSwift open source project.
//
//  HashType.swift last updated 02/06/2020
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

import Crypto
import Foundation

public protocol HashType: Codable, Comparable, CustomStringConvertible {
    var value: [UInt8] { get }

    init(value: [UInt8])

    static var size: Int { get }

    func hash(data: [UInt8]) -> Self

    static func hash(data: [UInt8]) -> Self
}

extension HashType {
    public var description: String {
        // TODO: put type implementing protocol instead of "Hash"
        "Hash<\(value.reduce("") { $0 + String(format: "%02X", $1) })>"
    }

    public static func leafHash(_ data: Data?) -> Self {
        // hash[0 + leaf]
        var d: [UInt8] = []
        if let data = data {
            d = [0] + [UInt8](data)
        }
        return Self.hash(data: d)
    }

    public static func innerHash(_ left: Self?, _ right: Self?) -> Self {
        // hash[1 + left + right]
        var d: [UInt8] = []
        if let left = left {
            d = [1] + left.value
        }
        if let right = right {
            d += right.value
        }
        return hash(data: d)
    }

    public var data: Data {
        Data(value)
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        // TODO: this is very inefficient
        lhs.value.reduce("") { $0 + String(format: "%02X", $1) } < rhs.value.reduce("") { $0 + String(format: "%02X", $1) }
    }
}

public typealias TMHash = TMHashClass

public struct TMHashStruct: HashType {
    public init() {
        self.init(value: [])
    }

    public func hash(data: [UInt8]) -> TMHashStruct {
        TMHashStruct(value: [UInt8](Crypto.SHA256.hash(data: data)))
    }

    public static func hash(data: [UInt8]) -> TMHashStruct {
        TMHashStruct(value: [UInt8](Crypto.SHA256.hash(data: data)))
    }

    public init(value: [UInt8]) {
        self.value = value
    }

    // 32 bytes
    public let value: [UInt8]

    public static let size: Int = 32
}

public final class TMHashClass: HashType {
    public static func == (lhs: TMHashClass, rhs: TMHashClass) -> Bool {
        lhs.value == rhs.value
    }

    public convenience init() {
        self.init(value: [])
    }

    public func hash(data: [UInt8]) -> TMHashClass {
        TMHashClass(value: [UInt8](Crypto.SHA256.hash(data: data)))
    }

    public static func hash(data: [UInt8]) -> TMHashClass {
        TMHashClass(value: [UInt8](Crypto.SHA256.hash(data: data)))
    }

    public init(value: [UInt8]) {
        self.value = value
    }

    // 32 bytes
    public let value: [UInt8]

    public static let size: Int = 32
}
