//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

/// Asserts that the queue the function is executed on, is the test queue with the given UUID.
///
/// - Parameters:
///   - id: The `id` of the expected test queue.
public func AssertTestQueue(withId id: UUID, file: StaticString = #file, line: UInt = #line) {
    if !DispatchQueue.isTestQueue(withId: id) {
        XCTFail("The current queue doesn't match the expected queue.", file: file, line: line)
    }
}

extension DispatchQueue {
    private static let queueIdKey = DispatchSpecificKey<String>()
    
    /// Creates a new queue which can be later identified by the id.
    static func testQueue(withId id: UUID) -> DispatchQueue {
        let queue = DispatchQueue(label: "Test queue: <\(id)>")
        queue.setSpecific(key: Self.queueIdKey, value: id.uuidString)
        return queue
    }
    
    /// Checks if the current queue is the queue with the given id.
    static func isTestQueue(withId id: UUID) -> Bool {
        DispatchQueue.getSpecific(key: queueIdKey) == id.uuidString
    }
}
