//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// Log level for any messages to be logged.
/// Please check [this Apple Logging Article](https://developer.apple.com/documentation/os/logging/generating_log_messages_from_your_code) to understand different logging levels.
public enum LogLevel: Int {
    /// Use this log level if you want to see everything that is logged.
    case debug = 0
    /// Use this log level if you want to see what is happening during the app execution.
    case info
    /// Use this log level if you want to see if something is not 100% right.
    case warning
    /// Use this log level if you want to see only errors.
    case error
}

/// Encapsulates the components of a log message.
public struct LogDetails {
    let loggerIdentifier: String
    
    let level: LogLevel
    let date: Date
    let message: String
    let threadName: String
    
    let functionName: StaticString
    let fileName: StaticString
    let lineNumber: UInt
}

public protocol LogDestination {
    var identifier: String { get set }
    var level: LogLevel { get set }
    
    var dateFormatter: DateFormatter { get set }
    var formatters: [LogFormatter] { get set }
    
    var showDate: Bool { get set }
    var showLevel: Bool { get set }
    var showIdentifier: Bool { get set }
    var showThreadName: Bool { get set }
    var showFileName: Bool { get set }
    var showLineNumber: Bool { get set }
    var showFunctionName: Bool { get set }
    
    func isEnabled(for level: LogLevel) -> Bool
    func process(logDetails: LogDetails)
    func applyFormatters(logDetails: LogDetails, message: String) -> String
    func write(message: String)
}
