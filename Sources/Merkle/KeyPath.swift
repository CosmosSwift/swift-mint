// ===----------------------------------------------------------------------===
//
//  This source file is part of the CosmosSwift open source project.
//
//  KeyPath.swift last updated 02/06/2020
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
import HexString

// TODO: from the go tests, this seems to be able to handle empty keys. I don't think the tests should pass, but needs to be confirmed
/*

 For generalized Merkle proofs, each layer of the proof may require an
 optional key.  The key may be encoded either by URL-encoding or
 (upper-case) hex-encoding.
 TODO: In the future, more encodings may be supported, like base32 (e.g.
 /32:)

 For example, for a Cosmos-SDK application where the first two proof layers
 are SimpleValueOps, and the third proof layer is an IAVLValueOp, the keys
 might look like:

 0: []byte("App")
 1: []byte("IBC")
 2: []byte{0x01, 0x02, 0x03}

 Assuming that we know that the first two layers are always ASCII texts, we
 probably want to use URLEncoding for those, whereas the third layer will
 require HEX encoding for efficient representation.

 kp := new(KeyPath)
 kp.AppendKey([]byte("App"), KeyEncodingURL)
 kp.AppendKey([]byte("IBC"), KeyEncodingURL)
 kp.AppendKey([]byte{0x01, 0x02, 0x03}, KeyEncodingURL)
 kp.String() // Should return "/App/IBC/x:010203"

 NOTE: Key paths must begin with a `/`.

 NOTE: All encodings *MUST* work compatibly, such that you can choose to use
 whatever encoding, and the decoded keys will always be the same.  In other
 words, it's just as good to encode all three keys using URL encoding or HEX
 encoding... it just wouldn't be optimal in terms of readability or space
 efficiency.

 NOTE: Punycode will never be supported here, because not all values can be
 decoded.  For example, no string decodes to the string "xn--blah" in
 Punycode.

 */

// a Key is represented by an Array of SubKey
public typealias Key = [SubKey]

public enum SubKey: Equatable, CustomStringConvertible {
    case empty
    case url(String)
    case hex(Data)

    public init?(_ string: String) {
        guard !string.isEmpty else { return nil }
        guard let string = string.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { return nil }
        self = .url(string)
    }

    public init?(_ data: Data) {
        guard !data.isEmpty else { return nil }
        self = .hex(data)
    }

    public init?(hex: String) {
        guard !hex.isEmpty else { return nil }
        guard let d = hex.toData() else { return nil }
        self = .hex(d)
    }

    public init?(path: String) {
        switch path.prefix(2) {
        case "x:":
            self.init(hex: String(path.dropFirst(2)))
        default:
            self.init(path)
        }
    }

    public init?(_ bytes: [UInt8]) {
        guard bytes.count != 0 else { return nil }
        self = .hex(Data(bytes))
    }

    public var path: String {
        switch self {
        case let .url(s):
            return s
        case let .hex(d):
            return "x:\(d.hex)"
        case .empty:
            return ""
        }
    }

    fileprivate init() {
        self = .empty
    }

    public static let emptyKey = SubKey()

    public func data() -> Data {
        switch self {
        case let .url(s):
            return Data(s.utf8)
        case let .hex(d):
            return d
        case .empty:
            return Data()
        }
    }

    public var description: String {
        switch self {
        case let .url(s):
            return s.removingPercentEncoding ?? "decode error: \(s)"
        case let .hex(d):
            return d.hex
        case .empty:
            return "<Empty Key>"
        }
    }
}

extension Array where Element == SubKey {
    // Decode a path to a list of keys.
    public init(string: String) throws {
        guard string.first! == "/" else { throw CosmosSwiftError.general("Path must begin with `/`.") }
        var res = [SubKey]()
        for subStr in string.split(separator: "/", omittingEmptySubsequences: false).dropFirst() {
            guard let r = SubKey(path: String(subStr)) else { throw CosmosSwiftError.general("Unknown encoding.") }
            res.append(r)
        }
        self = res
    }

    public var path: String {
        "/" + map { $0.path }.joined(separator: "/")
    }
}

extension String {
    // key to string
    init(key: [SubKey]) {
        self = key.path
    }
}
