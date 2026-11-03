//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Log levels used by the A2UI logger.
/// Higher levels indicate more severe messages.
enum A2UILogLevel: Int, Comparable, CaseIterable, Sendable {
    case all = 0
    case finest = 1
    case finer = 2
    case fine = 3
    case info = 4
    case warning = 5
    case severe = 6
    case off = 7

    var name: String {
        switch self {
        case .all: return "ALL"
        case .finest: return "FINEST"
        case .finer: return "FINER"
        case .fine: return "FINE"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .severe: return "SEVERE"
        case .off: return "OFF"
        }
    }

    /// Compares log levels by severity.
    /// Lower raw values are less severe.
    static func < (lhs: A2UILogLevel, rhs: A2UILogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Simple logger used throughout StreamChatA2UI.
/// Formats messages and routes them through a handler.
@MainActor
final class A2UILogger {
    let name: String
    var level: A2UILogLevel
    var handler: ((A2UILogLevel, String) -> Void)?

    /// Creates a logger with a name and initial level.
    /// Provide a handler to control log output.
    init(name: String, level: A2UILogLevel = .info) {
        self.name = name
        self.level = level
    }

    /// Logs a message at the specified level.
    /// Invokes the handler when the level is enabled.
    func log(_ level: A2UILogLevel, _ message: @autoclosure () -> String) {
        guard level >= self.level, level != .off else { return }
        let timestamp = ISO8601DateFormatter().string(from: Date())
        handler?(level, "[\(level.name)] \(timestamp): \(message())")
    }

    /// Logs a message at the finest level.
    /// Use for verbose tracing.
    func finest(_ message: @autoclosure () -> String) { log(.finest, message()) }
    /// Logs a message at the finer level.
    /// Use for detailed tracing.
    func finer(_ message: @autoclosure () -> String) { log(.finer, message()) }
    /// Logs a message at the fine level.
    /// Use for normal debugging.
    func fine(_ message: @autoclosure () -> String) { log(.fine, message()) }
    /// Logs an informational message.
    /// Use for high-level flow events.
    func info(_ message: @autoclosure () -> String) { log(.info, message()) }
    /// Logs a warning message.
    /// Use for recoverable issues.
    func warning(_ message: @autoclosure () -> String) { log(.warning, message()) }
    /// Logs a severe error message.
    /// Use for failures that need attention.
    func severe(_ message: @autoclosure () -> String) { log(.severe, message()) }
}

@MainActor let a2uiLogger = A2UILogger(name: "StreamChatA2UI")

/// Configures the global A2UI logger.
/// Sets the log level and output callback.
@MainActor @discardableResult
func configureA2UILogging(
    level: A2UILogLevel = .info,
    logCallback: ((A2UILogLevel, String) -> Void)? = nil
) -> A2UILogger {
    a2uiLogger.level = level
    a2uiLogger.handler = logCallback ?? { _, message in
        print(message)
    }
    return a2uiLogger
}

/// Formats errors for logs and for the messages sent back to agents.
enum A2UIErrorFormatter {
    /// Returns the most useful description available for an error.
    ///
    /// A2UI's own error types carry curated messages; other errors fall back to
    /// their localized description.
    static func describe(_ error: Error) -> String {
        switch error {
        case let error as A2UIFunctionError:
            return error.description
        case let error as A2UIDecodingError:
            return error.description
        case let error as DataModelError:
            return error.description
        case let error as A2UIExpressionError:
            return error.description
        case let error as A2UIDecodingFailure:
            return describe(error.error)
        default:
            return error.localizedDescription
        }
    }
}
