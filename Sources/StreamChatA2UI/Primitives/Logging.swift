//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// How serious a message of the A2UI logger is.
@available(iOS 15.0, macOS 12.0, *)
enum A2UILogLevel: Sendable {
    case debug
    case info
    case warning
    case error
}

/// Where the renderer's messages go. Without a handler they go nowhere: `A2UIRenderer` sends
/// them to StreamCore's logger, with the rest of the SDK's.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class A2UILogger {
    var handler: ((A2UILogLevel, String) -> Void)?

    func debug(_ message: @autoclosure () -> String) { send(.debug, message()) }
    func info(_ message: @autoclosure () -> String) { send(.info, message()) }
    func warning(_ message: @autoclosure () -> String) { send(.warning, message()) }
    func error(_ message: @autoclosure () -> String) { send(.error, message()) }

    private func send(_ level: A2UILogLevel, _ message: @autoclosure () -> String) {
        handler?(level, message())
    }
}

@available(iOS 15.0, macOS 12.0, *)
@MainActor let a2uiLogger = A2UILogger()

/// Formats errors for logs and for the messages sent back to agents.
@available(iOS 15.0, macOS 12.0, *)
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
