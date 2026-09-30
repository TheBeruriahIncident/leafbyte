//
//  QueueTests.swift
//  LeafByteTests
//
//  Created by Abigail Getman-Pickering on 1/5/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import CoreGraphics
@testable import LeafByte
import Testing

struct QueueTests {
    @Test
    func testQueue() {
        var queue = Queue()
        let point1 = CGPoint(x: 1, y: 2)
        let point2 = CGPoint(x: 4, y: 3)

        #expect(queue.isEmpty)
        queue.enqueue(point1)
        #expect(!queue.isEmpty)
        queue.enqueue(point2)
        #expect(!queue.isEmpty)
        #expect(point1 == queue.dequeue())
        #expect(!queue.isEmpty)
        #expect(point2 == queue.dequeue())
        #expect(queue.isEmpty)
        #expect(queue.dequeue() == nil)
    }
}
