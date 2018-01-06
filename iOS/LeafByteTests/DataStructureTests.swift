//
//  UnionFindTests.swift
//  LeafByteTests
//
//  Created by Adam Campbell on 1/5/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import XCTest
@testable import LeafByte

class DataStructureTests: XCTestCase {
    func testUnionFind() {
        let unionFind = UnionFind()
        unionFind.createSubsetWith(1)
        unionFind.createSubsetWith(-1)
        unionFind.createSubsetWith(2)
        unionFind.createSubsetWith(3)
        
        XCTAssertFalse(unionFind.checkIfSameSubset(3, and: 1))
        unionFind.combineSubsetsContaining(3, and: 1)
        XCTAssert(unionFind.checkIfSameSubset(3, and: 1))
        
        XCTAssertFalse(unionFind.checkIfSameSubset(1, and: 2))
        XCTAssertFalse(unionFind.checkIfSameSubset(3, and: 2))
        unionFind.combineSubsetsContaining(1, and: 2)
        XCTAssert(unionFind.checkIfSameSubset(1, and: 2))
        XCTAssert(unionFind.checkIfSameSubset(3, and: 2))
        
        unionFind.createSubsetWith(4)
        unionFind.createSubsetWith(5)
        unionFind.combineSubsetsContaining(4, and: 5)
        
        assertIsAPartition(unionFind: unionFind, partition: [1, 2, 3])
        assertIsAPartition(unionFind: unionFind, partition: [-1])
        assertIsAPartition(unionFind: unionFind, partition: [4, 5])
    }
    
    private func assertIsAPartition(unionFind: UnionFind, partition: Set<Int>) {
        for element in partition {
            let subsetIndex = unionFind.getSubsetIndexOf(element)!
            XCTAssertEqual(partition, unionFind.subsetIndexToPartitionedElements[subsetIndex])
        }
    }
}
