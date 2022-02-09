//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import StreamChatTestTools

class LoggerMock: Logger, Spy {
    var recordedFunctions: [String] = []

    func injectMock() {
        LogConfig.logger = self
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
