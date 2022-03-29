//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public var log: Logger {
    LogConfig.logger
}

public enum StreamRuntimeCheck {
    /// Enables assertions thrown by the Stream SDK.
    ///
    /// When set to false, a message will be logged on console, but the assertion will not be thrown.
    public static var assertionsEnabled = false
}

/// Entity for identifying which subsystem the log message comes from.
public struct LogSubsystem: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// All subsystems within the SDK.
    public static let all: LogSubsystem = [.database, .httpRequests, .webSocket, .other, .offlineSupport]
    
    /// The subsystem responsible for any other part of the SDK.
    /// This is the default subsystem value for logging, to be used when `subsystem` is not specified.
    public static let other = Self(rawValue: 1 << 0)
    
    /// The subsystem responsible for database operations.
    public static let database = Self(rawValue: 1 << 1)
    /// The subsystem responsible for HTTP operations.
    public static let httpRequests = Self(rawValue: 1 << 2)
    /// The subsystem responsible for websocket operations.
    public static let webSocket = Self(rawValue: 1 << 3)
    /// The subsystem responsible for offline support.
    public static let offlineSupport = Self(rawValue: 1 << 4)
}

public enum LogConfig {
    /// Identifier for the logger. Defaults to empty.
    public static var identifier = "" {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Output level for the logger.
    public static var level: LogLevel = .error {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Date formatter for the logger. Defaults to ISO8601
    public static var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return df
    }() {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Log formatters to be applied in order before logs are outputted. Defaults to empty (no formatters).
    /// Please see `LogFormatter` for more info.
    public static var formatters = [LogFormatter]() {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Toggle for showing date in logs
    public static var showDate = true {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Toggle for showing log level in logs
    public static var showLevel = true {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Toggle for showing identifier in logs
    public static var showIdentifier = false {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Toggle for showing thread name in logs
    public static var showThreadName = true {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Toggle for showing file name in logs
    public static var showFileName = true {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Toggle for showing line number in logs
    public static var showLineNumber = true {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Toggle for showing function name in logs
    public static var showFunctionName = true {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Subsystems for the logger
    public static var subsystems: LogSubsystem = .all {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Destination types this logger will use.
    ///
    /// Logger will initialize the destinations with its own parameters. If you want full control on the parameters, use `destinations` directly,
    /// where you can pass parameters to destination initializers yourself.
    public static var destinationTypes: [LogDestination.Type] = [ConsoleLogDestination.self] {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Destinations for the default logger. Please see `LogDestination`.
    /// Defaults to only `ConsoleLogDestination`, which only prints the messages.
    ///
    /// - Important: Other options in `ChatClientConfig.Logging` will not take affect if this is changed.
    public static var destinations: [LogDestination] = {
        destinationTypes.map {
            $0.init(
                identifier: identifier,
                level: level,
                subsystems: subsystems,
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
        }
    }() {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Underlying logger instance to control singleton.
    private static var _logger: Logger?
    
    /// Logger instance to be used by StreamChat.
    ///
    /// - Important: Other options in `LogConfig` will not take affect if this is changed.
    public static var logger: Logger {
        get {
            if let logger = _logger {
                return logger
            } else {
                _logger = Logger(identifier: identifier, destinations: destinations)
                return _logger!
            }
        }
        set {
            _logger = newValue
        }
    }
    
    /// Invalidates the current logger instance so it can be recreated.
    private static func invalidateLogger() {
        _logger = nil
    }
}

/// Entity used for logging messages.
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
        message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other
    ) {
        log(
            level,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: message(),
            subsystems: subsystems
        )
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
        message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other
    ) {
        let enabledDestinations = destinations.filter { $0.isEnabled(level: level, subsystems: subsystems) }
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
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) {
        log(
            .info,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: message(),
            subsystems: subsystems
        )
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
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) {
        log(
            .debug,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: message(),
            subsystems: subsystems
        )
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
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) {
        log(
            .warning,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: message(),
            subsystems: subsystems
        )
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
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) {
        log(
            .error,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: message(),
            subsystems: subsystems
        )
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
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) {
        guard !condition() else { return }
        if StreamRuntimeCheck.assertionsEnabled {
            Swift.assert(condition(), String(describing: message()), file: fileName, line: lineNumber)
        }
        log(
            .error,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: "Assert failed: \(message())",
            subsystems: subsystems
        )
    }
    
    /// Stops program execution with `Swift.assertionFailure`. In RELEASE builds only
    /// logs the failure.
    ///
    /// - Parameters:
    ///   - message: A custom message to log if `condition` is evaluated to false.
    public func assertionFailure(
        _ message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) {
        if StreamRuntimeCheck.assertionsEnabled {
            Swift.assertionFailure(String(describing: message()), file: fileName, line: lineNumber)
        }
        log(
            .error,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: "Assert failed: \(message())",
            subsystems: subsystems
        )
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
