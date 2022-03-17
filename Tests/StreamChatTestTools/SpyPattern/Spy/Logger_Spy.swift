//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class LoggerMock: Logger, Spy {
    var originalLogger: Logger?
    var recordedFunctions: [String] = []

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
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) {
        record()
    }

    override func assertionFailure(
        _ message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) {
        record()
    }
}
