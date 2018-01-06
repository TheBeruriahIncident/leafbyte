//
//  UnionFind.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/5/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

// A union-find allows us to keep track of a partition of a set of elements and combine partitions ( https://en.wikipedia.org/wiki/Disjoint-set_data_structure ).
// This implementation is adapted from https://github.com/raywenderlich/swift-algorithm-club/blob/master/Union-Find/UnionFind.playground/Sources/UnionFindWeightedQuickUnionPathCompression.swift .
// This implementation is explained well at https://github.com/raywenderlich/swift-algorithm-club/tree/master/Union-Find .
class UnionFind {
    var subsetIndexToPartitionedElements = [Int: Set<Int>]()
    
    private var elementToMinimalSubsetIndex = [Int: Int]()
    private var subsetIndexToParentSubsetIndex = [Int]()
    // This is only accurate for the top parent in a tree. It's used to help keep the trees balanced.
    private var subsetIndexToSize = [Int]()
    
    func createSubsetWith(_ element: Int) {
        let subsetIndex = subsetIndexToParentSubsetIndex.count
        elementToMinimalSubsetIndex[element] = subsetIndex
        subsetIndexToParentSubsetIndex.append(subsetIndex)
        subsetIndexToSize.append(1)
        subsetIndexToPartitionedElements[subsetIndex] = [element]
    }
    
    func getSubsetIndexOf(_ element: Int) -> Int? {
        if let indexOfElement = elementToMinimalSubsetIndex[element] {
            return getMaximalParentSubsetIndexBySubsetIndex(indexOfElement)
        } else {
            return nil
        }
    }
    
    // Note that the smaller set becomes a parent of the larger set to help keep balance.
    func combineSubsetsContaining(_ firstElement: Int, and secondElement: Int) {
        if let firstSet = getSubsetIndexOf(firstElement), let secondSet = getSubsetIndexOf(secondElement) {
            if firstSet != secondSet {
                var smallerSet: Int!
                var largerSet: Int!
                if subsetIndexToSize[firstSet] < subsetIndexToSize[secondSet] {
                    smallerSet = firstSet
                    largerSet = secondSet
                } else {
                    smallerSet = secondSet
                    largerSet = firstSet
                }
                
                subsetIndexToParentSubsetIndex[smallerSet] = largerSet
                subsetIndexToSize[largerSet] += subsetIndexToSize[smallerSet]
                subsetIndexToPartitionedElements[largerSet]!.formUnion(subsetIndexToPartitionedElements[smallerSet]!)
                subsetIndexToPartitionedElements[smallerSet] = nil
            }
        }
    }
    
    func checkIfSameSubset(_ firstElement: Int, and secondElement: Int) -> Bool {
        if let firstSet = getSubsetIndexOf(firstElement), let secondSet = getSubsetIndexOf(secondElement) {
            return firstSet == secondSet
        } else {
            return false
        }
    }
    
    // This helper incidentally compresses the path from subset to maximal parent subset.
    private func getMaximalParentSubsetIndexBySubsetIndex(_ index: Int) -> Int {
        if index != subsetIndexToParentSubsetIndex[index] {
            let parentSubsetIndex = subsetIndexToParentSubsetIndex[index]
            subsetIndexToParentSubsetIndex[index] = getMaximalParentSubsetIndexBySubsetIndex(parentSubsetIndex)
        }
        return subsetIndexToParentSubsetIndex[index]
    }
}
