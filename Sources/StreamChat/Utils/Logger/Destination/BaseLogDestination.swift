//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// Base class for log destinations. Already implements basic functionality to allow easy destination implementation.
/// Extending this class, instead of implementing `LogDestination` is easier (and recommended) for creating new destinations.
open class BaseLogDestination: LogDestination {
    open var identifier: String
    open var level: LogLevel
    open var subsystems: LogSubsystem
    
    open var dateFormatter: DateFormatter
    open var formatters: [LogFormatter]
    
    open var showDate: Bool
    open var showLevel: Bool
    open var showIdentifier: Bool
    open var showThreadName: Bool
    open var showFileName: Bool
    open var showLineNumber: Bool
    open var showFunctionName: Bool
    
    /// Initialize the log destination with given parameters.
    ///
    /// - Parameters:
    ///   - identifier: Identifier for this destination. Will be shown on the logs if `showIdentifier` is `true`
    ///   - level: Output level for this destination. Messages will only be shown if their output level is higher than this.
    ///   - showDate: Toggle for showing date in logs
    ///   - dateFormatter: DateFormatter instance for formatting the date in logs. Defaults to ISO8601 formatter.
    ///   - formatters: Log formatters to be applied in order before logs are outputted. Defaults to empty (no formatters).
    ///                 Please see `LogFormatter` for more info.
    ///   - showLevel: Toggle for showing log level in logs
    ///   - showIdentifier: Toggle for showing identifier in logs
    ///   - showThreadName: Toggle for showing thread name in logs
    ///   - showFileName: Toggle for showing file name in logs
    ///   - showLineNumber: Toggle for showing line number in logs
    ///   - showFunctionName: Toggle for showing function name in logs
    public required init(
        identifier: String,
        level: LogLevel,
        subsystems: LogSubsystem,
        showDate: Bool,
        dateFormatter: DateFormatter,
        formatters: [LogFormatter],
        showLevel: Bool,
        showIdentifier: Bool,
        showThreadName: Bool,
        showFileName: Bool,
        showLineNumber: Bool,
        showFunctionName: Bool
    ) {
        self.identifier = identifier
        self.level = level
        self.subsystems = subsystems
        self.showIdentifier = showIdentifier
        self.showThreadName = showThreadName
        self.showDate = showDate
        self.dateFormatter = dateFormatter
        self.formatters = formatters
        self.showLevel = showLevel
        self.showFileName = showFileName
        self.showLineNumber = showLineNumber
        self.showFunctionName = showFunctionName
    }
    
    open func isEnabled(level: LogLevel) -> Bool {
        assertionFailure("`isEnabled(level:)` is deprecated, please use `isEnabled(level:subsystem:)`")
        return true
    }
    
    /// Checks if this destination is enabled for the given level and subsystems.
    /// - Parameter level: Log level to be checked
    /// - Parameter subsystems: Log subsystems to be checked
    /// - Returns: `true` if destination is enabled for the given level, else `false`
    open func isEnabled(level: LogLevel, subsystems: LogSubsystem) -> Bool {
        level.rawValue >= self.level.rawValue && self.subsystems.contains(subsystems)
    }
    
    /// Process the log details before outputting the log.
    /// - Parameter logDetails: Log details to be processed.
    open func process(logDetails: LogDetails) {
        var extendedDetails: String = ""
        
        if showDate {
            extendedDetails += "\(dateFormatter.string(from: logDetails.date)) "
        }
        
        if showLevel {
            extendedDetails += "[\(String(describing: logDetails.level).uppercased())] "
        }
        
        if showIdentifier {
            extendedDetails += "[\(logDetails.loggerIdentifier)-\(identifier)] "
        }
        
        if showThreadName {
            extendedDetails += logDetails.threadName
        }
        
        if showFileName {
            let fileName = (String(describing: logDetails.fileName) as NSString).lastPathComponent
            extendedDetails += "[\(fileName)\(showLineNumber ? ":\(logDetails.lineNumber)" : "")] "
        } else if showLineNumber {
            extendedDetails += "[\(logDetails.lineNumber)] "
        }
        
        if showFunctionName {
            extendedDetails += "[\(logDetails.functionName)] "
        }
        
        let extendedMessage = "\(extendedDetails)> \(logDetails.message)"
        let formattedMessage = applyFormatters(logDetails: logDetails, message: extendedMessage)
        write(message: formattedMessage)
    }
    
    /// Apply formatters to the log message to be outputted
    /// Be aware that formatters are order dependent.
    /// - Parameters:
    ///   - logDetails: Log details to be passed on to formatters.
    ///   - message: Log message to be formatted
    /// - Returns: Formatted log message, formatted by all formatters in order.
    open func applyFormatters(logDetails: LogDetails, message: String) -> String {
        formatters.reduce(message) { $1.format(logDetails: logDetails, message: $0) }
    }
    
    /// Writes a given message to the desired output.
    /// By minimum, subclasses should implement this function, since it handles outputting the message.
    open func write(message: String) {
        assertionFailure("Please extend this class and implement this function!")
    }
}
