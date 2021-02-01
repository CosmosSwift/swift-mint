// ===----------------------------------------------------------------------===
//
//  This source file is part of the CosmosSwift open source project.
//
//  ProofSimpleValue.swift last updated 02/06/2020
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

public struct SimpleValueOp<Hash: HashType, Codec: CoderType>: ProofOperatorProtocol {
    public let key: Data
    let proof: SimpleProof<Hash>

//    // TODO: this should really be handled by a relevant Codec
//    public init(pop: ProofOp) {
//        self.key = pop.key.data()
//       self.proof = try! SimpleProof<Hash>(total: 0, index: 0, leafHash: Hash(value: []), aunts: []) //pop.data // TODO: deserialize as SimpleProof<Hash> using Codec
//    }

    public func run(_ data: [Data]) throws -> [Data] {
        if data.count != 1 {
            throw CosmosSwiftError.general("expected 1 arg, got \(data.count)")
        }

        // calculate hash of value
        let vhash = Hash.hash(data: [UInt8](data.first!)) // data.count == 1

        // Wrap <op.Key, vhash> to hash the KVPair.
        var encoded = Data()
        encoded.append(contentsOf: (try? Codec.encode(key)) ?? Data())
        encoded.append(contentsOf: (try? Codec.encode(vhash.data)) ?? Data())

        let kvhash = Hash.leafHash(encoded)

        if kvhash != proof.leafHash {
            throw CosmosSwiftError.general("leaf hash mismatch: want \(kvhash) got \(proof.leafHash)")
        }

        return [Data(try proof.computeRootHash().value)]
    }

    public let type: String = "SimpleValueOp"

//    public var data: Data? {
//        get {
//            // TODO: implement properly
//            Codec.mustMarshalBinaryLengthPrefixed(self)
//        }
//    }
}
