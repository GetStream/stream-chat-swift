//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
    public let loggerIdentifier: String
    
    public let level: LogLevel
    public let date: Date
    public let message: String
    public let threadName: String
    
    public let functionName: StaticString
    public let fileName: StaticString
    public let lineNumber: UInt
}

public protocol LogDestination {
    var identifier: String { get set }
    var level: LogLevel { get set }
    var subsystems: LogSubsystem { get set }
    
    var dateFormatter: DateFormatter { get set }
    var formatters: [LogFormatter] { get set }
    
    var showDate: Bool { get set }
    var showLevel: Bool { get set }
    var showIdentifier: Bool { get set }
    var showThreadName: Bool { get set }
    var showFileName: Bool { get set }
    var showLineNumber: Bool { get set }
    var showFunctionName: Bool { get set }
    
    func isEnabled(level: LogLevel) -> Bool
    func isEnabled(level: LogLevel, subsystems: LogSubsystem) -> Bool
    func process(logDetails: LogDetails)
    func applyFormatters(logDetails: LogDetails, message: String) -> String
    func write(message: String)
}

public extension LogDestination {
    var subsystems: LogSubsystem { .all }
    
    func isEnabled(level: LogLevel, subsystems: LogSubsystem) -> Bool {
        isEnabled(level: level) && self.subsystems.contains(subsystems)
    }
}
