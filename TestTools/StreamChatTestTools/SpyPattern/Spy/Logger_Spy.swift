//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class Logger_Spy: Logger, Spy {
    var originalLogger: Logger?
    var recordedFunctions: [String] = []
    var failedAsserts: Int = 0

    func injectMock() {
        let logger = LogConfig.logger
        if logger.self === Logger.self {
            originalLogger = logger
        }
        LogConfig.logger = self
    }

    func restoreLogger() {
        guard let originalLogger = originalLogger else { return }
        LogConfig.logger = originalLogger
    }

    var assertCalls: Int {
        numberOfCalls(on: "assert(_:_:subsystems:functionName:fileName:lineNumber:)")
    }

    var assertionFailureCalls: Int {
        numberOfCalls(on: "assertionFailure(_:subsystems:functionName:fileName:lineNumber:)")
    }

    override func assert(
        _ condition: @autoclosure () -> Bool,
        _ message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #filePath,
        lineNumber: UInt = #line
    ) {
        record()
        failedAsserts += condition() ? 0 : 1
    }

    override func assertionFailure(
        _ message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #filePath,
        lineNumber: UInt = #line
    ) {
        record()
        failedAsserts += 1
    }
}
