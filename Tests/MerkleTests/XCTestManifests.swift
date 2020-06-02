// ===----------------------------------------------------------------------===
//
//  This source file is part of the CosmosSwift open source project.
//
//  XCTestManifests.swift last updated 02/06/2020
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

import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        return [
            testCase(MerkleTests.allTests),
            testCase(RFC6962Tests.allTests),
            testCase(SimpleProofTests.allTests),
            testCase(ProofTests.allTests),
            testCase(KeyPathTests.allTests),
            testCase(SimpleMapTests.allTests),
        ]
    }
#endif
