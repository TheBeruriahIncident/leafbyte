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
        
        XCTAssertFalse(unionFind.checkIfSameClass(3, and: 1))
        unionFind.combineClassesContaining(3, and: 1)
        XCTAssert(unionFind.checkIfSameClass(3, and: 1))
        
        XCTAssertFalse(unionFind.checkIfSameClass(1, and: 2))
        XCTAssertFalse(unionFind.checkIfSameClass(3, and: 2))
        unionFind.combineClassesContaining(1, and: 2)
        XCTAssert(unionFind.checkIfSameClass(1, and: 2))
        XCTAssert(unionFind.checkIfSameClass(3, and: 2))
        
        unionFind.createSubsetWith(4)
        unionFind.createSubsetWith(5)
        unionFind.combineClassesContaining(4, and: 5)
        
        assertIsAPartition(unionFind: unionFind, partition: [1, 2, 3])
        assertIsAPartition(unionFind: unionFind, partition: [-1])
        assertIsAPartition(unionFind: unionFind, partition: [4, 5])
    }
    
    private func assertIsAPartition(unionFind: UnionFind, partition: Set<Int>) {
        for element in partition {
            let elementClass = unionFind.getClassOf(element)!
            XCTAssertEqual(partition, unionFind.classToElements[elementClass])
        }
    }
}
