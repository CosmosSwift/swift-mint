// ===----------------------------------------------------------------------===
//
//  This source file is part of the CosmosSwift open source project.
//
//  SimpleMap.swift last updated 02/06/2020
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

// Merkle tree from a map.
// Leaves are `hash(key) | hash(value)`.
// Leaves are sorted before Merkle hashing.
public struct SimpleMap<Hash: HashType, Codec: CoderType> {
    struct KVPair: Comparable {
        let k: Data
        let v: Hash

        init(_ key: String, _ value: Data) {
            // The value is hashed, so you can
            // check for equality with a cached value (say)
            // and make a determination to fetch or not.
            k = Data(key.utf8)
            v = Hash.hash(data: [UInt8](value))
        }

        static func == (lhs: SimpleMap<Hash, Codec>.KVPair, rhs: SimpleMap<Hash, Codec>.KVPair) -> Bool {
            lhs.k == rhs.k && lhs.v == rhs.v
        }

        static func < (lhs: SimpleMap<Hash, Codec>.KVPair, rhs: SimpleMap<Hash, Codec>.KVPair) -> Bool {
            lhs.k.hex < rhs.k.hex || ((lhs.k == rhs.k) && (lhs.v < rhs.v))
        }

        var encoded: Data {
            var res = Data()
            res.append(contentsOf: Codec.encode(k))
            res.append(contentsOf: Codec.encode(v.data))
            return res
        }
    }

    var kvs: [KVPair]
    var sorted: Bool = false

    public init(_ map: [String: Data]) {
        kvs = map.map { KVPair($0.key, $0.value) }
    }

    // Set creates a kv pair of the key and the hash of the value,
    // and then appends it to simpleMap's kv pairs.
    public mutating func set(_ key: String, _ value: Data) {
        sorted = false
        kvs.append(KVPair(key, value))
    }

    mutating func sort() {
        if !sorted {
            kvs.sort()
            sorted = true
        }
    }

    // Hash Merkle root hash of items sorted by key
    // (UNSTABLE: and by value too if duplicate key).
    public mutating func hash() -> Hash? {
        sort()
        return simpleHashFromByteSlices(kvs.map { $0.encoded })
    }
}

/*

  // TODO: is this needed?

 // Returns a copy of sorted KVPairs.
 // NOTE these contain the hashed key and value.
 func (sm *simpleMap) KVPairs() kv.Pairs {
     sm.Sort()
     kvs := make(kv.Pairs, len(sm.kvs))
     copy(kvs, sm.kvs)
     return kvs
 }
 */
