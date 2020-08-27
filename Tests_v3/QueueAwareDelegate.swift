//
// Copyright © 2020 Stream.io Inc. All rights reserved.
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
    // If set, checks the delegate was called on the correct queue
    var expectedQueueId: UUID?
    
    let file: StaticString
    let line: UInt
    
    init(file: StaticString = #file, line: UInt = #line) {
        self.file = file
        self.line = line
    }
    
    func validateQueue(function: StaticString = #function) {
        if let queueId = expectedQueueId {
            XCTAssertTrue(
                DispatchQueue.isTestQueue(withId: queueId),
                "Delegate method \(function) called on an incorrect queue",
                file: file,
                line: line
            )
        }
    }
}
