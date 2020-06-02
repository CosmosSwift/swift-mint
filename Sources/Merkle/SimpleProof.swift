// ===----------------------------------------------------------------------===
//
//  This source file is part of the CosmosSwift open source project.
//
//  SimpleProof.swift last updated 02/06/2020
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

// MaxAunts is the maximum number of aunts that can be included in a SimpleProof.
// This corresponds to a tree of size 2^100, which should be sufficient for all conceivable purposes.
// This maximum helps prevent Denial-of-Service attacks by limitting the size of the proofs.
let MAX_AUNTS = 100

// SimpleProof represents a simple Merkle proof.
// NOTE: The convention for proofs is to include leaf hashes but to
// exclude the root hash.
// This convention is implemented across IAVL range proofs as well.
// Keep this consistent unless there's a very good reason to change
// everything.  This also affects the generalized proof system as
// well.
public struct SimpleProof<Hash: HashType>: Codable, CustomStringConvertible {
    let total: Int // Total number of items.
    let index: Int // Index of item to prove.
    let leafHash: Hash // Hash of item value.
    let aunts: [Hash] // Hashes from leaf's sibling to a root's child.

    // Throwing initialiser performs basic validation.
    // NOTE: it expects the LeafHash and the elements of Aunts to be of size Hash.Size (this is enforced through the Hash),
    // and it expects at most MaxAunts elements in Aunts.
    public init(total: Int, index: Int, leafHash: Hash, aunts: [Hash]) throws {
        guard total >= 0, index < total, index >= 0 else { throw CosmosSwiftError.general("index (\(index) or total \(total) invalid or inconsistent") }
        guard aunts.count <= MAX_AUNTS else { throw CosmosSwiftError.general("Too many aunts \(aunts.count) > MAX_AUNT: \(MAX_AUNTS)") }
        self.total = total
        self.index = index
        self.leafHash = leafHash
        self.aunts = aunts
    }

    enum CodingKeys: String, CodingKey {
        case total
        case index
        case leafHash = "leaf_hash"
        case aunts
    }

    // TODO: add encode and decode

    // Verify that the SimpleProof proves the root hash.
    func verify(_ rootHash: Hash, _ leaf: Data) throws {
        let lH = Hash.leafHash(leaf)
        guard leafHash == lH else { throw CosmosSwiftError.general("invalid leaf hash: wanted \(leafHash) got \(lH)") }

        let computedHash = try computeRootHash()
        guard rootHash == computedHash else { throw CosmosSwiftError.general("invalid root hash: wanted \(rootHash) got \(computedHash)") }
    }

    // Compute the root hash given a leaf hash. Does not verify the result.
    func computeRootHash() throws -> Hash {
        return try computeHashFromAunts(total, index, leafHash, aunts)
    }

    public var description: String {
        """
        SimpleProof {
        total:    \(total)
        index:    \(index)
        leafHash: \(leafHash)
        aunts:    \(aunts)
        }
        """
    }
}

// Use the leafHash and innerHashes to get the root merkle hash.
// If the length of the innerHashes slice isn't exactly correct, the result is nil.
// Recursive impl.
func computeHashFromAunts<Hash: HashType>(_ total: Int, _ index: Int, _ leafHash: Hash, _ innerHashes: [Hash]) throws -> Hash {
    guard index < total, total > 0 else { throw CosmosSwiftError.general("Index out of range \(index) >= \(total)") }
    let maxIndex = innerHashes.count - 1
    switch total {
    case 0:
        throw CosmosSwiftError.general("Cannot call computeHashFromAunts() with 0 total - should never be reached")
    case 1:
        guard innerHashes.count == 0 else { throw CosmosSwiftError.general("Innerhash should be empty for leaf node") }
        return leafHash
    default:
        guard innerHashes.count != 0 else { throw CosmosSwiftError.general("Innerhash should not be empty for internal node") }
        let numLeft = try getSplitPoint(total)
        if index < numLeft {
            guard let leftHash = try? computeHashFromAunts(numLeft, index, leafHash, innerHashes.dropLast()) else { throw CosmosSwiftError.general("leftHash should not be nil") }

            return Hash.innerHash(leftHash, innerHashes[maxIndex])
        } else {
            guard let rightHash = try? computeHashFromAunts(total - numLeft, index - numLeft, leafHash, innerHashes.dropLast()) else { throw CosmosSwiftError.general("rightHash should not be nil") }
            return Hash.innerHash(innerHashes[maxIndex], rightHash)
        }
    }
}

// SimpleProofsFromByteSlices computes inclusion proof for given items.
// proofs[0] is the proof for items[0].
func simpleProofsFromByteSlices<Hash: HashType>(_ items: [Data]) throws -> (Hash, [SimpleProof<Hash>]) {
    let (trails, rootSPN): (trails: [SimpleProofNode<Hash>], root: SimpleProofNode<Hash>) = trailsFromByteSlices(items)
    let rootHash = rootSPN.hash
    var proofs: [SimpleProof<Hash>] = []
    for (i, trail) in trails.enumerated() {
        proofs.append(try SimpleProof(total: items.count, index: i, leafHash: trail.hash, aunts: trail.flattenAunts()))
    }
    return (rootHash, proofs)
}

// SimpleProofsFromMap generates proofs from a map. The keys/values of the map will be used as the keys/values
// in the underlying key-value pairs.
// The keys are sorted before the proofs are computed.
// swiftlint:disable large_tuple
func simpleProofsFromMap<Hash: HashType, Codec: CoderType>(_ map: [String: Data], _: Codec.Type) throws -> (Hash, [String: SimpleProof<Hash>], [String]) {
    let sm = SimpleMap<Hash, Codec>(map)

    let (root, proofList): (Hash, [SimpleProof<Hash>]) = try simpleProofsFromByteSlices(sm.kvs.map { $0.encoded })

    var proofs: [String: SimpleProof<Hash>] = [:]
    var keys: [String] = []
    for (i, k) in sm.kvs.enumerated() {
        let s = String(data: k.k, encoding: .utf8)!
        proofs[s] = proofList[i]
        keys.append(s)
    }

//    sm := newSimpleMap()
//    for k, v := range m {
//        sm.Set(k, v)
//    }
//    sm.Sort()
//    kvs := sm.kvs
//    kvsBytes := make([][]byte, len(kvs))
//    for i, kvp := range kvs {
//        kvsBytes[i] = KVPair(kvp).Bytes()
//    }

//    rootHash, proofList := SimpleProofsFromByteSlices(kvsBytes)
//    proofs = make(map[string]*SimpleProof)
//    keys = make([]string, len(proofList))
//    for i, kvp := range kvs {
//        proofs[string(kvp.Key)] = proofList[i]
//        keys[i] = string(kvp.Key)
//    }
//    return

    return (root, proofs, keys)
}

class SimpleProofNode<Hash: HashType> {
    enum Side {
        case empty
        case left(SimpleProofNode<Hash>)
        case right(SimpleProofNode<Hash>)
    }

    let hash: Hash
    var parent: SimpleProofNode<Hash>?
    var child: Side

    init(_ hash: Hash, _ child: Side) {
        self.hash = hash
        self.child = child
    }

    // FlattenAunts will return the inner hashes for the item corresponding to the leaf,
    // starting from a leaf SimpleProofNode.
    func flattenAunts() -> [Hash] {
        // Nonrecursive impl.
        var innerHashes: [Hash] = []
        var current: SimpleProofNode<Hash>? = self
        while current != nil {
            switch current!.child {
            case let .left(spn):
                innerHashes.append(spn.hash)
            case let .right(spn):
                innerHashes.append(spn.hash)
            default:
                break
            }
            current = current!.parent
        }
        return innerHashes
    }
}

// trails[0].hash is the leaf hash for items[0].
// trails[i].parent.parent....parent == root for all i.
func trailsFromByteSlices<Hash: HashType>(_ items: [Data]) -> (trails: [SimpleProofNode<Hash>], root: SimpleProofNode<Hash>) {
    return trailsFromByteSlices(items[0 ..< items.count])
}

func trailsFromByteSlices<Hash: HashType>(_ items: ArraySlice<Data>) -> (trails: [SimpleProofNode<Hash>], root: SimpleProofNode<Hash>) {
    // Recursive impl.
    let size = items.count
    switch size {
    case 0:
        return ([SimpleProofNode<Hash>](), SimpleProofNode<Hash>(Hash(value: []), .empty))
    case 1:
        let trail = SimpleProofNode<Hash>(Hash.leafHash(items.first), .empty)
        return ([trail], trail)
    default: // size > 2
        // swiftlint:disable force_try
        let k = try! getSplitPoint(size) // only throws when size < 1, k > 1
        let (lefts, leftRoot): (trails: [SimpleProofNode<Hash>], root: SimpleProofNode<Hash>) = trailsFromByteSlices(items.prefix(k))
        let (rights, rightRoot): (trails: [SimpleProofNode<Hash>], root: SimpleProofNode<Hash>) = trailsFromByteSlices(items.suffix(size - k))

        let root = SimpleProofNode<Hash>(Hash.innerHash(leftRoot.hash, rightRoot.hash), .empty)
        leftRoot.parent = root
        leftRoot.child = .right(rightRoot)
        rightRoot.parent = root
        rightRoot.child = .left(leftRoot)
        return (lefts + rights, root)
    }
}
