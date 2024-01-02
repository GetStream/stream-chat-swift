//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest

/// A delegate superclass which can verify a certain method was called on the given queue.
///
/// Example usage:
/// ```
/// class TestMyDelegate: QueueAwareDelegate {
///   func controllerWillStartFetchingRemoteData(_ controller: Controller) {
///       validateQueue()
///   }
/// }
/// ```
open class QueueAwareDelegate {
    // Checks the delegate was called on the correct queue
    public let expectedQueueId: UUID
    public let file: StaticString
    public let line: UInt
    
    public init(expectedQueueId: UUID, file: StaticString = #filePath, line: UInt = #line) {
        self.expectedQueueId = expectedQueueId
        self.file = file
        self.line = line
    }
    
    public func validateQueue(function: StaticString = #function) {
        XCTAssertTrue(
            DispatchQueue.isTestQueue(withId: expectedQueueId),
            "Delegate method \(function) called on an incorrect queue",
            file: file,
            line: line
        )
    }
}
