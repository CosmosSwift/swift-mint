// ===----------------------------------------------------------------------===
//
//  This source file is part of the CosmosSwift open source project.
//
//  Proof.swift last updated 02/06/2020
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

//
public struct ProofOp {
    public let type: String
    public let key: SubKey
    public let data: Data
}

typealias Proof = [ProofOp]

//

// ----------------------------------------
// ProofOp gets converted to an instance of ProofOperator:

// ProofOperator is a layer for calculating intermediate Merkle roots
// when a series of Merkle trees are chained together.
// Run() takes leaf values from a tree and returns the Merkle
// root for the corresponding tree. It takes and returns a list of bytes
// to allow multiple leaves to be part of a single proof, for instance in a range proof.
// ProofOp() encodes the ProofOperator in a generic way so it can later be
// decoded with OpDecoder.

public protocol ProofOperatorProtocol: Codable {
    associatedtype Key: DataProtocol, Equatable
    associatedtype Data: DataProtocol

    func run(_ data: [Data]) throws -> [Data]
    var key: Key { get }
    var type: String { get }
//    var data: Data? {get}
}

// extension ProofOp { // TODO: this should be handled by a Codec
//    public init?<ProofOperator: ProofOperatorProtocol>(proofOp: ProofOperator) {
//        self.type = proofOp.type
//        guard let k = SubKey(Data(proofOp.key)) else {
//            return nil
//        }
//        self.key = k
//        guard let d = proofOp.data else {
//            return nil
//        }
//        self.data = Data(d)
//    }
// }

// ----------------------------------------
// Operations on a list of ProofOperators

// ProofOperators is a slice of ProofOperator(s).
// Each operator will be applied to the input value sequentially
// and the last Merkle root will be verified with already known data

public typealias ProofOperators = [ProofOperatorProtocol]

extension Array where Element: ProofOperatorProtocol {
    public func verifyValue<Hash: HashType>(root: Hash, key: [Element.Key], value: Element.Data) throws {
        try verify(root: root, key: key, args: [value])
    }

    public func verify<Hash: HashType>(root: Hash, key: [Element.Key], args: [Element.Data]) throws {
        // poz = self
        var data = args
        // condition: key should have the same number of subKeys as self
        let keyLength = key.count
//        let filtered = self.filter { (sk) -> Bool in
//            sk.key.path != ""
//        }
        let filtered = self
        let selfKeyLength = filtered.count
        guard keyLength == selfKeyLength else { throw CosmosSwiftError.general("key path has  \(keyLength) subkeys but expected \(selfKeyLength)") }

        // run args = op.run(args) on each subkey in order
        // abort with error if one fails
        // when completed, root and args[0] need to match to verify

        for (idx, op) in filtered.enumerated() {
            let k = op.key
            // condition: key and self must have the same components in reverse order
            guard k == key[keyLength - idx - 1] else { throw CosmosSwiftError.general("key mismatch on operation \(idx): expected \(k) but got \(key[keyLength - idx - 1])") }
            data = try op.run(data)
        }
        guard root == Hash.hash(data: [UInt8](data[0])) else { throw CosmosSwiftError.general("calculated root hash is invalid: expected \(root) but got \(data[0])") }

        // TODO: need to check if this allows empty keys (see ProofTests)
        /*
         keys, err := KeyPathToKeys(keypath)
         if err != nil {
             return
         }

         for i, op := range poz {
             key := op.GetKey()
             if len(key) != 0 {
                 if len(keys) == 0 {
                     return errors.Errorf("key path has insufficient # of parts: expected no more keys but got %+v", string(key))
                 }
                 lastKey := keys[len(keys)-1]
                 if !bytes.Equal(lastKey, key) {
                     return errors.Errorf("key mismatch on operation #%d: expected %+v but got %+v", i, string(lastKey), string(key))
                 }
                 keys = keys[:len(keys)-1]
             }
             args, err = op.Run(args)
             if err != nil {
                 return
             }
         }
         if !bytes.Equal(root, args[0]) {
             return errors.Errorf("calculated root hash is invalid: expected %+v but got %+v", root, args[0])
         }
         if len(keys) != 0 {
             return errors.New("keypath not consumed all")
         }
         return nil
         */
    }
}

// TODO: When implementing milestone 2, check if this is necessary:
/*
 //----------------------------------------
 // ProofRuntime - main entrypoint

 type OpDecoder func(ProofOp) (ProofOperator, error)

 type ProofRuntime struct {
     decoders map[string]OpDecoder
 }

 func NewProofRuntime() *ProofRuntime {
     return &ProofRuntime{
         decoders: make(map[string]OpDecoder),
     }
 }

 func (prt *ProofRuntime) RegisterOpDecoder(typ string, dec OpDecoder) {
     _, ok := prt.decoders[typ]
     if ok {
         panic("already registered for type " + typ)
     }
     prt.decoders[typ] = dec
 }

 func (prt *ProofRuntime) Decode(pop ProofOp) (ProofOperator, error) {
     decoder := prt.decoders[pop.Type]
     if decoder == nil {
         return nil, errors.Errorf("unrecognized proof type %v", pop.Type)
     }
     return decoder(pop)
 }

 func (prt *ProofRuntime) DecodeProof(proof *Proof) (ProofOperators, error) {
     poz := make(ProofOperators, 0, len(proof.Ops))
     for _, pop := range proof.Ops {
         operator, err := prt.Decode(pop)
         if err != nil {
             return nil, errors.Wrap(err, "decoding a proof operator")
         }
         poz = append(poz, operator)
     }
     return poz, nil
 }

 func (prt *ProofRuntime) VerifyValue(proof *Proof, root []byte, keypath string, value []byte) (err error) {
     return prt.Verify(proof, root, keypath, [][]byte{value})
 }

 // TODO In the long run we'll need a method of classifcation of ops,
 // whether existence or absence or perhaps a third?
 func (prt *ProofRuntime) VerifyAbsence(proof *Proof, root []byte, keypath string) (err error) {
     return prt.Verify(proof, root, keypath, nil)
 }

 func (prt *ProofRuntime) Verify(proof *Proof, root []byte, keypath string, args [][]byte) (err error) {
     poz, err := prt.DecodeProof(proof)
     if err != nil {
         return errors.Wrap(err, "decoding proof")
     }
     return poz.Verify(root, keypath, args)
 }

 // DefaultProofRuntime only knows about Simple value
 // proofs.
 // To use e.g. IAVL proofs, register op-decoders as
 // defined in the IAVL package.
 func DefaultProofRuntime() (prt *ProofRuntime) {
     prt = NewProofRuntime()
     prt.RegisterOpDecoder(ProofOpSimpleValue, SimpleValueOpDecoder)
     return
 }
 */
