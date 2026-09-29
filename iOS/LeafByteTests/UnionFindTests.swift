//
//  UnionFindTests.swift
//  LeafByteTests
//
//  Created by Abigail Getman-Pickering on 1/5/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

@testable import LeafByte
import Testing

struct UnionFindTests {
    @Test
    func testUnionFind() throws {
        let unionFind = UnionFind()
        unionFind.createSubsetWith(1)
        unionFind.createSubsetWith(-1)
        unionFind.createSubsetWith(2)
        unionFind.createSubsetWith(3)

        #expect(!unionFind.checkIfSameClass(3, and: 1))
        unionFind.combineClassesContaining(3, and: 1)
        #expect(unionFind.checkIfSameClass(3, and: 1))

        #expect(!unionFind.checkIfSameClass(1, and: 2))
        #expect(!unionFind.checkIfSameClass(3, and: 2))
        unionFind.combineClassesContaining(1, and: 2)
        #expect(unionFind.checkIfSameClass(1, and: 2))
        #expect(unionFind.checkIfSameClass(3, and: 2))

        unionFind.createSubsetWith(4)
        unionFind.createSubsetWith(5)
        unionFind.combineClassesContaining(4, and: 5)

        try assertIsAPartition(unionFind: unionFind, partition: [1, 2, 3])
        try assertIsAPartition(unionFind: unionFind, partition: [-1])
        try assertIsAPartition(unionFind: unionFind, partition: [4, 5])
    }

    private func assertIsAPartition(unionFind: UnionFind, partition: Set<Int>) throws {
        for element in partition {
            let elements = try #require(unionFind.getElementsInClassWith(element))
            #expect(partition == elements)
        }
    }
}
