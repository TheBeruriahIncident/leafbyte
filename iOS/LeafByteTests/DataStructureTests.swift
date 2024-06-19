//
//  UnionFindTests.swift
//  LeafByteTests
//
//  Created by Abigail Getman-Pickering on 1/5/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import XCTest
@testable import LeafByte

final class DataStructureTests: XCTestCase {
    func testQueue() {
        var queue = Queue();
        let point1 = CGPoint(x: 1, y: 2)
        let point2 = CGPoint(x: 4, y: 3)

        XCTAssert(queue.isEmpty)
        queue.enqueue(point1)
        XCTAssertFalse(queue.isEmpty)
        queue.enqueue(point2)
        XCTAssertFalse(queue.isEmpty)
        XCTAssertEqual(point1, queue.dequeue())
        XCTAssertFalse(queue.isEmpty)
        XCTAssertEqual(point2, queue.dequeue())
        XCTAssert(queue.isEmpty)
        XCTAssertEqual(nil, queue.dequeue())
    }

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
            XCTAssertEqual(partition, unionFind.getElementsInClassWith(element)!)
        }
    }
}
