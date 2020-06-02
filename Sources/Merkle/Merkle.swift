// ===----------------------------------------------------------------------===
//
//  This source file is part of the CosmosSwift open source project.
//
//  Merkle.swift last updated 02/06/2020
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
// SimpleHashFromByteSlices computes a Merkle tree where the leaves are the byte slice,
// in the provided order.
public func simpleHashFromByteSlices<Hash: HashType>(_ items: [Data]) -> Hash? {
    // the current version of the iterative algoritm is abt 40% faster than the recursive one
    return simpleHashFromByteSlicesIterative(items)
}

public func simpleHashFromByteSlicesRecursive<Hash: HashType>(_ items: [Data]) -> Hash? {
    return simpleHashFromByteSlicesRecursive(items[0 ..< items.count])
}

private func simpleHashFromByteSlicesRecursive<Hash: HashType>(_ items: ArraySlice<Data>) -> Hash? {
    let size = items.count
    switch size {
    case 0:
        return nil
    case 1:
        return Hash.leafHash(items.first)
    default:
        guard let k = try? getSplitPoint(size) else {
            return nil
        }
        let left: Hash? = simpleHashFromByteSlicesRecursive(items.prefix(k))
        let right: Hash? = simpleHashFromByteSlicesRecursive(items.suffix(size - k))
        return Hash.innerHash(left, right)
    }
}

/*
 // SimpleHashFromByteSliceIterative is an iterative alternative to
 // SimpleHashFromByteSlice motivated by potential performance improvements.
 // (#2611) had suggested that an iterative version of
 // SimpleHashFromByteSlice would be faster, presumably because
 // we can envision some overhead accumulating from stack
 // frames and function calls. Additionally, a recursive algorithm risks
 // hitting the stack limit and causing a stack overflow should the tree
 // be too large.
 //
 // Provided here is an iterative alternative, a simple test to assert
 // correctness and a benchmark. On the performance side, there appears to
 // be no overall difference:
 //
 // BenchmarkSimpleHashAlternatives/recursive-4                20000 77677 ns/op
 // BenchmarkSimpleHashAlternatives/iterative-4                20000 76802 ns/op
 //
 // On the surface it might seem that the additional overhead is due to
 // the different allocation patterns of the implementations. The recursive
 // version uses a single [][]byte slices which it then re-slices at each level of the tree.
 // The iterative version reproduces [][]byte once within the function and
 // then rewrites sub-slices of that array at each level of the tree.
 //
 // Experimenting by modifying the code to simply calculate the
 // hash and not store the result show little to no difference in performance.
 //
 // These preliminary results suggest:
 //
 // 1. The performance of the SimpleHashFromByteSlice is pretty good
 // 2. Go has low overhead for recursive functions
 // 3. The performance of the SimpleHashFromByteSlice routine is dominated
 //    by the actual hashing of data
 //
 // Although this work is in no way exhaustive, point #3 suggests that
 // optimization of this routine would need to take an alternative
 // approach to make significant improvements on the current performance.
 //
 // Finally, considering that the recursive implementation is easier to
 // read, it might not be worthwhile to switch to a less intuitive
 // implementation for so little benefit.
 */

public func simpleHashFromByteSlicesIterative<Hash: HashType>(_ items: [Data]) -> Hash? {
    var hashes = items.map { (d) -> Hash in
        Hash.leafHash(d)
    }

    var size = hashes.count
    while true {
        switch size {
        case 0:
            return nil
        case 1:
            return hashes[0]
        default:
            var rp = 0 // read position
            var wp = 0 // write position
            while rp < size {
                if rp + 1 < size {
                    hashes[wp] = Hash.innerHash(hashes[rp], hashes[rp + 1])
                    rp += 2
                } else {
                    hashes[wp] = hashes[rp]
                    rp += 1
                }
                wp += 1
            }
            size = wp
        }
    }
}

// SimpleHashFromMap computes a Merkle tree from sorted map.
// Like calling simpleHashFromHashers with
// `item = []byte(Hash(key) | Hash(value))`,
// sorted by `item`.
public func simpleHashFromMap<Hash: HashType, Codec: CoderType>(_ map: [String: Data], _: Codec.Type) -> Hash? {
    var sm = SimpleMap<Hash, Codec>(map)
    return sm.hash()
}

// getSplitPoint returns the largest power of 2 less than length
// -> getSplitPoint >= length/2
public func getSplitPoint(_ length: Int) throws -> Int {
    guard length > 0 else { throw CosmosSwiftError.general("Trying to split a tree with size < 1") }
    if length == 1 { return 0 }
    var i = 0
    var j = MemoryLayout<Int>.size * 8 / 2
    while i < j - 1 {
        let mid = (j + i) >> 1
        if length > (1 << mid) {
            i = mid
        } else if length <= (1 << mid) {
            j = mid
        }
    }
    return 1 << i
}
