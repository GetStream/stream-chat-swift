//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public var log: Logger {
    LogConfig.logger
}

/// Entity for identifying which subsystem the log message comes from.
public struct LogSubsystem: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// All subsystems within the SDK.
    public static let all: LogSubsystem = [.database, .httpRequests, .webSocket, .other, .offlineSupport, .authentication, .audioPlayback]

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
    /// The subsystem responsible for authentication.
    public static let authentication = Self(rawValue: 1 << 5)
    /// The subsystem responsible for audio playback.
    public static let audioPlayback = Self(rawValue: 1 << 6)
    /// The subsystem responsible for audio recording.
    public static let audioRecording = Self(rawValue: 1 << 7)
}

public enum LogConfig {
    /// Identifier for the logger. Defaults to empty.
    public static var identifier: String {
        get {
            queue.sync { _storage.identifier }
        }
        set {
            queue.async { _storage.identifier = newValue }
            invalidateLogger()
        }
    }

    /// Output level for the logger. Defaults to error.
    public static var level: LogLevel {
        get {
            queue.sync { _storage.level }
        }
        set {
            queue.async { _storage.level = newValue }
            invalidateLogger()
        }
    }

    /// Date formatter for the logger. Defaults to ISO8601
    public static var dateFormatter: DateFormatter {
        get {
            queue.sync { _storage.dateFormatter }
        }
        set {
            queue.async { _storage.dateFormatter = newValue }
            invalidateLogger()
        }
    }

    /// Log formatters to be applied in order before logs are outputted. Defaults to empty (no formatters).
    /// Please see `LogFormatter` for more info.
    public static var formatters: [LogFormatter] {
        get {
            queue.sync { _storage.formatters }
        }
        set {
            queue.sync { _storage.formatters = newValue }
            invalidateLogger()
        }
    }

    /// Toggle for showing date in logs. Defaults to true.
    public static var showDate: Bool {
        get {
            queue.sync { _storage.showDate }
        }
        set {
            queue.async { _storage.showDate = newValue }
            invalidateLogger()
        }
    }

    /// Toggle for showing log level in logs. Defaults to true.
    public static var showLevel: Bool {
        get {
            queue.sync { _storage.showLevel }
        }
        set {
            queue.async { _storage.showLevel = newValue }
            invalidateLogger()
        }
    }

    /// Toggle for showing identifier in logs. Defaults to false.
    public static var showIdentifier: Bool {
        get {
            queue.sync { _storage.showIdentifier }
        }
        set {
            queue.async { _storage.showIdentifier = newValue }
            invalidateLogger()
        }
    }

    /// Toggle for showing thread name in logs. Defaults to true.
    public static var showThreadName: Bool {
        get {
            queue.sync { _storage.showThreadName }
        }
        set {
            queue.async { _storage.showThreadName = newValue }
            invalidateLogger()
        }
    }

    /// Toggle for showing file name in logs. Defaults to true.
    public static var showFileName: Bool {
        get {
            queue.sync { _storage.showFileName }
        }
        set {
            queue.async { _storage.showFileName = newValue }
            invalidateLogger()
        }
    }

    /// Toggle for showing line number in logs. Defaults to true.
    public static var showLineNumber: Bool {
        get {
            queue.sync { _storage.showLineNumber }
        }
        set {
            queue.async { _storage.showLineNumber = newValue }
            invalidateLogger()
        }
    }

    /// Toggle for showing function name in logs. Defaults to true.
    public static var showFunctionName: Bool {
        get {
            queue.sync { _storage.showFunctionName }
        }
        set {
            queue.async { _storage.showFunctionName = newValue }
            invalidateLogger()
        }
    }

    /// Subsystems for the logger. Defaults to ``LogSubsystem.all``.
    public static var subsystems: LogSubsystem {
        get {
            queue.sync { _storage.subsystems }
        }
        set {
            queue.async { _storage.subsystems = newValue }
            invalidateLogger()
        }
    }

    /// Destination types this logger will use. Defaults to ``ConsoleLogDestination``.
    ///
    /// Logger will initialize the destinations with its own parameters. If you want full control on the parameters, use `destinations` directly,
    /// where you can pass parameters to destination initializers yourself.
    public static var destinationTypes: [LogDestination.Type] {
        get {
            queue.sync { _storage.destinationTypes }
        }
        set {
            queue.async { _storage.destinationTypes = newValue }
            invalidateLogger()
        }
    }

    /// Destinations for the default logger. Please see `LogDestination`.
    /// Defaults to only `ConsoleLogDestination`, which only prints the messages.
    ///
    /// - Important: Other options in `ChatClientConfig.Logging` will not take affect if this is changed.
    public static var destinations: [LogDestination] {
        get {
            queue.sync {
                if let destinations = _storage.destinations {
                    return destinations
                } else {
                    return _setDefaultDestinationsIfNeeded()
                }
            }
        }
        set {
            invalidateLogger()
            queue.async { _storage.destinations = newValue }
        }
    }
    
    private static func _setDefaultDestinationsIfNeeded() -> [LogDestination] {
        if let destinations = _storage.destinations {
            return destinations
        }
        _storage.destinations = _storage.destinationTypes.map {
            $0.init(
                identifier: _storage.identifier,
                level: _storage.level,
                subsystems: _storage.subsystems,
                showDate: _storage.showDate,
                dateFormatter: _storage.dateFormatter,
                formatters: _storage.formatters,
                showLevel: _storage.showLevel,
                showIdentifier: _storage.showIdentifier,
                showThreadName: _storage.showThreadName,
                showFileName: _storage.showFileName,
                showLineNumber: _storage.showLineNumber,
                showFunctionName: _storage.showFunctionName
            )
        }
        return _storage.destinations!
    }

    private static let queue = DispatchQueue(label: "io.getstream.logconfig")
    
    /// Guarded manually with a queue
    nonisolated(unsafe) private static var _storage: Storage = Storage()
    
    /// Logger instance to be used by StreamChat.
    ///
    /// - Important: Other options in `LogConfig` will not take affect if this is changed.
    public static var logger: Logger {
        get {
            queue.sync {
                if let logger = _storage.logger {
                    return logger
                } else {
                    let destinations = _setDefaultDestinationsIfNeeded()
                    let logger = Logger(identifier: _storage.identifier, destinations: destinations)
                    _storage.logger = logger
                    return logger
                }
            }
        }
        set {
            queue.sync { _storage.logger = newValue }
        }
    }

    /// Invalidates the current logger instance so it can be recreated.
    private static func invalidateLogger() {
        queue.async {
            _storage.logger = nil
            _storage.destinations = nil
        }
    }
}

extension LogConfig {
    struct Storage {
        init() {
            dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        }
        
        var logger: Logger?
        
        var identifier: String = ""
        var level: LogLevel = .error
        var dateFormatter: DateFormatter
        var formatters = [LogFormatter]()
        var showDate = true
        var showLevel = true
        var showIdentifier = false
        var showThreadName = true
        var showFileName = true
        var showLineNumber = true
        var showFunctionName = true
        var subsystems: LogSubsystem = .all
        var destinationTypes: [LogDestination.Type] = [ConsoleLogDestination.self]
        var destinations: [LogDestination]?
    }
}

/// Entity used for logging messages.
public class Logger {
    /// Identifier of the Logger. Will be visible if a destination has `showIdentifiers` enabled.
    public let identifier: String

    /// Destinations for this logger.
    /// See `LogDestination` protocol for details.
    public var destinations: [LogDestination] {
        get {
            loggerQueue.sync {
                _destinations
            }
        }
        set {
            loggerQueue.async { [weak self] in
                self?._destinations = newValue
            }
        }
    }

    private var _destinations: [LogDestination]

    private let loggerQueue = DispatchQueue(label: "io.getstream.logger")

    /// Init a logger with a given identifier and destinations.
    public init(identifier: String = "", destinations: [LogDestination] = []) {
        self.identifier = identifier
        _destinations = destinations
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

        // The message() closure should be done from the thread it was called.
        // In some scenarios message() will print out managedObjectContexts and in this case
        // it is important the closure is performed in the managedObjectContext's thread.
        let messageString = String(describing: message())

        // Read the thread name before dispatching the log to the desired destinations,
        // so that we have the name of the thread that actually initiated the log.
        let threadName = threadName

        loggerQueue.async { [weak self] in
            guard let self = self else { return }

            let logDetails = LogDetails(
                loggerIdentifier: self.identifier,
                level: level,
                date: Date(),
                message: messageString,
                threadName: threadName,
                functionName: functionName,
                fileName: fileName,
                lineNumber: lineNumber
            )
            for destination in enabledDestinations {
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

// Mutable state is guarded with a queue.
extension Logger: @unchecked Sendable {}

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
