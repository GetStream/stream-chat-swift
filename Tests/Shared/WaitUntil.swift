//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {
    func waitUntil(timeout: TimeInterval = 0.5, _ action: (_ done: @escaping () -> Void) -> Void) {
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
