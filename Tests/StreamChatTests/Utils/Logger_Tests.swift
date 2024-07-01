//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
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
    
    func test_restoringInjectedLogger() {
        XCTAssertTrue(type(of: LogConfig.logger) == Logger.self)
        let spyLogger = Logger_Spy()
        spyLogger.injectMock()
        XCTAssertTrue(type(of: LogConfig.logger) == Logger_Spy.self)
        spyLogger.restoreLogger()
        XCTAssertTrue(type(of: LogConfig.logger) == Logger.self)
    }
}
