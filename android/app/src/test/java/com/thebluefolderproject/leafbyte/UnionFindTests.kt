/**
 * Copyright © 2020 Zoe Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte

import com.thebluefolderproject.leafbyte.utils.UnionFind
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

final class DataStructureTests {

    @Test
    fun testUnionFind() {
        val unionFind = UnionFind()
        unionFind.createSubsetWith(1)
        unionFind.createSubsetWith(-1)
        unionFind.createSubsetWith(2)
        unionFind.createSubsetWith(3)
        assertFalse(unionFind.checkIfSameClass(3, 1))
        unionFind.combineClassesContaining(3, 1)
        assert(unionFind.checkIfSameClass(3, 1))
        assertFalse(unionFind.checkIfSameClass(1, 2))
        assertFalse(unionFind.checkIfSameClass(3, 2))
        unionFind.combineClassesContaining(1, 2)
        assert(unionFind.checkIfSameClass(1, 2))
        assert(unionFind.checkIfSameClass(3, 2))
        unionFind.createSubsetWith(4)
        unionFind.createSubsetWith(5)
        unionFind.combineClassesContaining(4, 5)
        assertIsAPartition(unionFind = unionFind, partition = setOf(1, 2, 3))
        assertIsAPartition(unionFind = unionFind, partition = setOf(-1))
        assertIsAPartition(unionFind = unionFind, partition = setOf(4, 5))
    }

    private fun assertIsAPartition(unionFind: UnionFind, partition: Set<Int>) {
        for (element in partition) {
            assertEquals(partition, unionFind.getElementsInClassWith(element)!!)
        }
    }
}
