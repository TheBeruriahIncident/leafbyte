//
//  UnionFind.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/5/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

// A union-find allows us to keep track of a partition of a set of elements and combine equivalence classes ( https://en.wikipedia.org/wiki/Disjoint-set_data_structure ).
// This implementation is adapted from https://github.com/raywenderlich/swift-algorithm-club/blob/master/Union-Find/UnionFind.playground/Sources/UnionFindWeightedQuickUnionPathCompression.swift .
// This implementation is explained well at https://github.com/raywenderlich/swift-algorithm-club/tree/master/Union-Find .
final class UnionFind {
    var classToElements = [Int: Set<Int>]()

    private var elementToSubset = [Int: Int]()
    private var subsetToParentSubset = [Int]()
    // This is only accurate for the top parent in a tree. It's used to help keep the trees balanced.
    private var subsetToSize = [Int]()

    func createSubsetWith(_ element: Int) {
        let subsetIndex = subsetToParentSubset.count
        elementToSubset[element] = subsetIndex
        subsetToParentSubset.append(subsetIndex)
        subsetToSize.append(1)
        classToElements[subsetIndex] = [element]
    }

    func getElementsInClassWith(_ element: Int) -> Set<Int>? {
        if let elementClass = getClassOf(element) {
            return classToElements[elementClass]
        } else {
            return nil
        }
    }

    func getClassOf(_ element: Int) -> Int? {
        if let indexOfElement = elementToSubset[element] {
            return getClassBySubset(indexOfElement)
        } else {
            return nil
        }
    }

    // Note that the smaller set becomes a parent of the larger set to help keep balance.
    func combineClassesContaining(_ firstElement: Int, and secondElement: Int) {
        if let firstSet = getClassOf(firstElement), let secondSet = getClassOf(secondElement) {
            if firstSet != secondSet {
                var smallerSet: Int
                var largerSet: Int
                if subsetToSize[firstSet] < subsetToSize[secondSet] {
                    smallerSet = firstSet
                    largerSet = secondSet
                } else {
                    smallerSet = secondSet
                    largerSet = firstSet
                }

                subsetToParentSubset[smallerSet] = largerSet
                subsetToSize[largerSet] += subsetToSize[smallerSet]
                classToElements[largerSet]!.formUnion(classToElements[smallerSet]!)
                classToElements[smallerSet] = nil
            }
        }
    }

    func checkIfSameClass(_ firstElement: Int, and secondElement: Int) -> Bool {
        if let firstSet = getClassOf(firstElement), let secondSet = getClassOf(secondElement) {
            return firstSet == secondSet
        } else {
            return false
        }
    }

    // This helper incidentally compresses the path from subset to class.
    private func getClassBySubset(_ index: Int) -> Int {
        if index != subsetToParentSubset[index] {
            let parentSubsetIndex = subsetToParentSubset[index]
            subsetToParentSubset[index] = getClassBySubset(parentSubsetIndex)
        }
        return subsetToParentSubset[index]
    }
}
