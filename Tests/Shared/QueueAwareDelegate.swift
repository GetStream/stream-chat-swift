//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

/// A delegate superclass which can verify a certain method was called on the given queue.
///
/// Example usage:
/// ```
/// class MyDelegate: QueueAwareDelegate {
///   func controllerWillStartFetchingRemoteData(_ controller: Controller) {
///       validateQueue()
///   }
/// }
/// ```
class QueueAwareDelegate {
    // Checks the delegate was called on the correct queue
    let expectedQueueId: UUID
    let file: StaticString
    let line: UInt
    
    init(expectedQueueId: UUID, file: StaticString = #file, line: UInt = #line) {
        self.expectedQueueId = expectedQueueId
        self.file = file
        self.line = line
    }
    
    func validateQueue(function: StaticString = #function) {
        XCTAssertTrue(
            DispatchQueue.isTestQueue(withId: expectedQueueId),
            "Delegate method \(function) called on an incorrect queue",
            file: file,
            line: line
        )
    }
}
