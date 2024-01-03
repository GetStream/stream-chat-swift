//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {
    public func waitUntil(timeout: TimeInterval = 0.5, _ action: (_ done: @escaping () -> Void) -> Void) {
        let expectation = XCTestExpectation(description: "Action completed")
        action {
            if Thread.isMainThread {
                expectation.fulfill()
            } else {
                DispatchQueue.main.async {
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: timeout)
    }
}
