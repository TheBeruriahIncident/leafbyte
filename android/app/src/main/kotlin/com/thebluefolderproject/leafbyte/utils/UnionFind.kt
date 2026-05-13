/*
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.utils

// A union-find allows us to keep track of a partition of a set of elements and combine equivalence classes ( https://en.wikipedia.org/wiki/Disjoint-set_data_structure ).
// This implementation is adapted from https://github.com/raywenderlich/swift-algorithm-club/blob/master/Union-Find/UnionFind.playground/Sources/UnionFindWeightedQuickUnionPathCompression.swift .
// This implementation is explained well at https://github.com/raywenderlich/swift-algorithm-club/tree/master/Union-Find .
@Suppress("all")
final class UnionFind {
    var classToElements = mutableMapOf<Int, MutableSet<Int>>()
    private var elementToSubset = mutableMapOf<Int, Int>()
    private var subsetToParentSubset = mutableListOf<Int>()
    private // This is only accurate for the top parent in a tree. It's used to help keep the trees balanced.
    var subsetToSize = mutableListOf<Int>()

    fun createSubsetWith(element: Int) {
        val subsetIndex = subsetToParentSubset.size
        elementToSubset[element] = subsetIndex
        subsetToParentSubset.add(subsetIndex)
        subsetToSize.add(1)
        classToElements[subsetIndex] = mutableSetOf(element)
    }

    fun getElementsInClassWith(element: Int): Set<Int>? {
        val elementClass = getClassOf(element)
        if (elementClass != null) {
            return classToElements[elementClass]
        } else {
            return null
        }
    }

    fun getClassOf(element: Int): Int? {
        val indexOfElement = elementToSubset[element]
        if (indexOfElement != null) {
            return getClassBySubset(indexOfElement)
        } else {
            return null
        }
    }

    // Note that the smaller set becomes a parent of the larger set to help keep balance.
    fun combineClassesContaining(
        firstElement: Int,
        secondElement: Int,
    ) {
        val firstSet = getClassOf(firstElement)
        val secondSet = getClassOf(secondElement)
        if (firstSet != null && secondSet != null) {
            if (firstSet != secondSet) {
                val smallerSet: Int
                val largerSet: Int
                if (subsetToSize[firstSet] < subsetToSize[secondSet]) {
                    smallerSet = firstSet
                    largerSet = secondSet
                } else {
                    smallerSet = secondSet
                    largerSet = firstSet
                }

                subsetToParentSubset[smallerSet] = largerSet
                subsetToSize[largerSet] += subsetToSize[smallerSet]
                classToElements[largerSet]!!.addAll(classToElements[smallerSet]!!)
                classToElements.remove(smallerSet)
            }
        }
    }

    fun checkIfSameClass(
        firstElement: Int,
        secondElement: Int,
    ): Boolean {
        val firstSet = getClassOf(firstElement)
        val secondSet = getClassOf(secondElement)
        if (firstSet != null && secondSet != null) {
            return firstSet == secondSet
        } else {
            return false
        }
    }

    // This helper incidentally compresses the path from subset to class.
    private fun getClassBySubset(index: Int): Int {
        if (index != subsetToParentSubset[index]) {
            val parentSubsetIndex = subsetToParentSubset[index]
            subsetToParentSubset[index] = getClassBySubset(parentSubsetIndex)
        }
        return subsetToParentSubset[index]
    }
}
