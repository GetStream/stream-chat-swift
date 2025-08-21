//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
    public let file: StaticString
    public let line: UInt
    
    public init(file: StaticString = #filePath, line: UInt = #line) {
        self.file = file
        self.line = line
    }
    
    public func validateQueue(function: StaticString = #function) {
        XCTAssertTrue(
            Thread.isMainThread,
            "Delegate method \(function) called on an incorrect queue",
            file: file,
            line: line
        )
    }
}
