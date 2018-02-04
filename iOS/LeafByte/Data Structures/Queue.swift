//
//  Queue.swift
//  LeafByte
//
//  Created by Adam Campbell on 2/3/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import CoreGraphics

// A queue ( https://en.wikipedia.org/wiki/Queue_(abstract_data_type) ) can be implemented with just an array, but then each deque is O(n).
// This implementation is adapted from https://github.com/raywenderlich/swift-algorithm-club/blob/master/Queue/Queue-Optimized.swift .
// This implementation is explained well at https://github.com/raywenderlich/swift-algorithm-club/tree/master/Queue .
public struct Queue {
    private var array = [CGPoint?]()
    private var head = 0
    
    public var isEmpty: Bool {
        return array.count - head == 0
    }
    
    public mutating func enqueue(_ point: CGPoint) {
        array.append(point)
    }
    
    public mutating func dequeue() -> CGPoint? {
        guard head < array.count, let point = array[head] else {
            return nil
        }
        
        array[head] = nil
        head += 1

        // If the array is more than half nil, eliminate the dequeued spots.
        // Don't bother with this on small arrays (smaller than 50).
        if array.count > 50 && Double(head) / Double(array.count) > 0.5 {
            array.removeFirst(head)
            head = 0
        }
        
        return point
    }
}
