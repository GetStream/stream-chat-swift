//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public var log: Logger {
    LogConfig.logger
}

public enum LogConfig {
    /// Identifier for the logger. Defaults to empty.
    public static var identifier = ""
    
    /// Output level for the logger.
    public static var level: LogLevel = .error
    
    /// Date formatter for the logger. Defaults to ISO8601
    public static var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return df
    }()
    
    /// Log formatters to be applied in order before logs are outputted. Defaults to empty (no formatters).
    /// Please see `LogFormatter` for more info.
    public static var formatters = [LogFormatter]()
    
    /// Toggle for showing date in logs
    public static var showDate = true
    
    /// Toggle for showing log level in logs
    public static var showLevel = true
    
    /// Toggle for showing identifier in logs
    public static var showIdentifier = false
    
    /// Toggle for showing thread name in logs
    public static var showThreadName = true
    
    /// Toggle for showing file name in logs
    public static var showFileName = true
    
    /// Toggle for showing line number in logs
    public static var showLineNumber = true
    
    /// Toggle for showing function name in logs
    public static var showFunctionName = true
    
    /// Destinations for the default logger. Please see `LogDestination`.
    /// Defaults to only `ConsoleLogDestination`, which only prints the messages.
    ///
    /// - Important: Other options in `ChatClientConfig.Logging` will not take affect if this is changed.
    public static var destinations: [LogDestination] = {
        let consoleLogDestination = ConsoleLogDestination(
            level: level,
            showDate: showDate,
            dateFormatter: dateFormatter,
            formatters: formatters,
            showLevel: showLevel,
            showIdentifier: showIdentifier,
            showThreadName: showThreadName,
            showFileName: showFileName,
            showLineNumber: showLineNumber,
            showFunctionName: showFunctionName
        )
        return [consoleLogDestination]
    }()
    
    /// Logger instance to be used by StreamChat.
    ///
    /// - Important: Other options in `ChatClientConfig.Logging` will not take affect if this is changed.
    public static var logger: Logger = {
        Logger(identifier: identifier, destinations: destinations)
    }()
}

/// Entitiy used for loggin messages.
public class Logger {
    /// Identifier of the Logger. Will be visible if a destination has `showIdentifiers` enabled.
    public let identifier: String
    
    /// Destinations for this logger.
    /// See `LogDestination` protocol for details.
    public var destinations: [LogDestination]
    
    private let loggerQueue = DispatchQueue(label: "LoggerQueue \(UUID())")
    
    /// Init a logger with a given identifier and destinations.
    public init(identifier: String = "", destinations: [LogDestination] = []) {
        self.identifier = identifier
        self.destinations = destinations
    }
    
    /// Allows logger to be called as function.
    /// Transforms, given that `let log = Logger()`, `log.log(.info, "Hello")` to `log(.info, "Hello")` for ease of use.
    ///
    /// - Parameters:
    ///   - level: Log level for this message
    ///   - functionName: Function of the caller
    ///   - fileName: File of the caller
    ///   - lineNumber: Line number of the caller
    ///   - message: Message to be logged
    public func callAsFunction(
        _ level: LogLevel,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line,
        message: @autoclosure () -> Any
    ) {
        log(level, functionName: functionName, fileName: fileName, lineNumber: lineNumber, message: message())
    }
    
    /// Log a message to all enabled destinations.
    /// See  `Logger.destinations` for customizing the output.
    ///
    /// - Parameters:
    ///   - level: Log level for this message
    ///   - functionName: Function of the caller
    ///   - fileName: File of the caller
    ///   - lineNumber: Line number of the caller
    ///   - message: Message to be logged
    public func log(
        _ level: LogLevel,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line,
        message: @autoclosure () -> Any
    ) {
        let enabledDestinations = destinations.filter { $0.isEnabled(for: level) }
        guard !enabledDestinations.isEmpty else { return }
        
        let logDetails = LogDetails(
            loggerIdentifier: identifier,
            level: level,
            date: Date(),
            message: String(describing: message()),
            threadName: threadName,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber
        )
        for destination in enabledDestinations {
            loggerQueue.async {
                destination.process(logDetails: logDetails)
            }
        }
    }
    
    /// Log an info message.
    ///
    /// - Parameters:
    ///   - message: Message to be logged
    ///   - functionName: Function of the caller
    ///   - fileName: File of the caller
    ///   - lineNumber: Line number of the caller
    public func info(
        _ message: @autoclosure () -> Any,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) {
        log(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, message: message())
    }
    
    /// Log a debug message.
    ///
    /// - Parameters:
    ///   - message: Message to be logged
    ///   - functionName: Function of the caller
    ///   - fileName: File of the caller
    ///   - lineNumber: Line number of the caller
    public func debug(
        _ message: @autoclosure () -> Any,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) {
        log(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, message: message())
    }
    
    /// Log a warning message.
    ///
    /// - Parameters:
    ///   - message: Message to be logged
    ///   - functionName: Function of the caller
    ///   - fileName: File of the caller
    ///   - lineNumber: Line number of the caller
    public func warning(
        _ message: @autoclosure () -> Any,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) {
        log(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, message: message())
    }
    
    /// Log an error message.
    ///
    /// - Parameters:
    ///   - message: Message to be logged
    ///   - functionName: Function of the caller
    ///   - fileName: File of the caller
    ///   - lineNumber: Line number of the caller
    public func error(
        _ message: @autoclosure () -> Any,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) {
        log(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, message: message())
    }
    
    /// Performs `Swift.assert` and stops program execution if `condition` evaluated to false. In RELEASE builds only
    /// logs the failure.
    ///
    /// - Parameters:
    ///   - condition: The condition to test.
    ///   - message: A custom message to log if `condition` is evaluated to false.
    public func assert(
        _ condition: @autoclosure () -> Bool,
        _ message: @autoclosure () -> Any,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) {
        guard !condition() else { return }
        Swift.assert(condition(), String(describing: message()), file: fileName, line: lineNumber)
        log(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, message: "Assert failed: \(message())")
    }
    
    /// Stops program execution with `Swift.assertationFailure`. In RELEASE builds only
    /// logs the failure.
    ///
    /// - Parameters:
    ///   - message: A custom message to log if `condition` is evaluated to false.
    public func assertationFailure(
        _ message: @autoclosure () -> Any,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) {
        Swift.assertionFailure(String(describing: message()), file: fileName, line: lineNumber)
        log(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, message: "Assert failed: \(message())")
    }
}

private extension Logger {
    var threadName: String {
        if Thread.isMainThread {
            return "[main] "
        } else {
            if let threadName = Thread.current.name, !threadName.isEmpty {
                return "[\(threadName)] "
            } else if let queueName = String(validatingUTF8: __dispatch_queue_get_label(nil)), !queueName.isEmpty {
                return "[\(queueName)] "
            } else {
                return String(format: "[%p] ", Thread.current)
            }
        }
    }
}

extension Data {
    /// Converts the data into a pretty-printed JSON string. Use only for debug purposes since this operation can be expensive.
    var debugPrettyPrintedJSON: String {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: self, options: [.allowFragments])
            let prettyPrintedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
            return String(data: prettyPrintedData, encoding: .utf8) ?? "Error: Data to String decoding failed."
        } catch {
            return "JSON decoding failed with error: \(error)"
        }
    }
}
