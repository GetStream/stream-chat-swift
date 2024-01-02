//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

import Foundation
@testable import StreamChat
import XCTest

final class Logger_Tests: XCTestCase {
    func test_log_isThreadSafe() {
        LogConfig.destinationTypes = [ConsoleLogDestination.self]

        DispatchQueue.concurrentPerform(iterations: 1000) { _ in
            log.error("should not crash")
        }

        DispatchQueue.concurrentPerform(iterations: 1000) { _ in
            log.warning("should not crash")
        }

        DispatchQueue.concurrentPerform(iterations: 1000) { _ in
            log.debug("should not crash")
        }

        DispatchQueue.concurrentPerform(iterations: 1000) { _ in
            log.info("should not crash")
        }
    }
}
