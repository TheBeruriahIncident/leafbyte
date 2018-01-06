//
//  UnionFind.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/5/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

// Taken from https://github.com/raywenderlich/swift-algorithm-club/blob/master/Union-Find/UnionFind.playground/Sources/UnionFindWeightedQuickUnionPathCompression.swift
class UnionFind <T: Hashable> {
    private var index = [T: Int]()
    private var parent = [Int]()
    private var size = [Int]()
    
    public init() {}
    
    public func addSetWith(_ element: T) {
        index[element] = parent.count
        parent.append(parent.count)
        size.append(1)
    }
    
    /// Path Compression.
    private func setByIndex(_ index: Int) -> Int {
        if index != parent[index] {
            parent[index] = setByIndex(parent[index])
        }
        return parent[index]
    }
    
    public func setOf(_ element: T) -> Int? {
        if let indexOfElement = index[element] {
            return setByIndex(indexOfElement)
        } else {
            return nil
        }
    }
    
    public func unionSetsContaining(_ firstElement: T, and secondElement: T) {
        if let firstSet = setOf(firstElement), let secondSet = setOf(secondElement) {
            if firstSet != secondSet {
                if size[firstSet] < size[secondSet] {
                    parent[firstSet] = secondSet
                    size[secondSet] += size[firstSet]
                } else {
                    parent[secondSet] = firstSet
                    size[firstSet] += size[secondSet]
                }
            }
        }
    }
    
    public func inSameSet(_ firstElement: T, and secondElement: T) -> Bool {
        if let firstSet = setOf(firstElement), let secondSet = setOf(secondElement) {
            return firstSet == secondSet
        } else {
            return false
        }
    }
}
