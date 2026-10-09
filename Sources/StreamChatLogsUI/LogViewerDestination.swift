//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamLogsUI

/// A log destination that records logs in `InMemoryLogRecorder.shared`, so that they are displayed in the log viewer.
///
/// `LogViewer.install()` adds it to the logger. To manage the logger's destinations yourself instead,
/// add it to `LogConfig.destinationTypes` or `LogConfig.destinations`.
public final class LogViewerDestination: BaseLogDestination, @unchecked Sendable {
    static let consoleID = "console"
    static let logViewerID = "logViewer"

    override public func isEnabled(level: LogLevel, subsystems: LogSubsystem) -> Bool {
        InMemoryLogRecorder.shared.isRecording && super.isEnabled(level: level, subsystems: subsystems)
    }

    override public func process(logDetails: LogDetails) {
        InMemoryLogRecorder.shared.record(LogEntry(logDetails))
    }
}

extension LogEntry {
    init(_ logDetails: LogDetails) {
        self.init(
            date: logDetails.date,
            level: Level(logDetails.level),
            subsystems: LogSubsystem.allCases.filter { logDetails.subsystem.contains($0) }.map(LogEntry.Subsystem.init),
            threadName: logDetails.threadName,
            functionName: logDetails.functionName,
            fileName: logDetails.fileName,
            lineNumber: logDetails.lineNumber,
            message: logDetails.message,
            error: logDetails.error,
            metadata: logDetails.attachment.map { [MetadataKey: String]($0) } ?? [:]
        )
    }
}

extension Dictionary where Key == LogEntry.MetadataKey, Value == String {
    init(_ attachment: any LogAttachment) {
        switch attachment {
        case let http as HTTPLogAttachment:
            self = .http(
                request: http.request,
                response: http.response,
                responseBody: http.responseBody,
                error: http.error,
                session: http.session
            )
        case let webSocket as WebSocketLogAttachment:
            let payloadKey: Key = webSocket.direction == .sent ? .webSocketSentPayload : .webSocketReceivedPayload
            self = [payloadKey: webSocket.logDescription]
            let object = try? JSONSerialization.jsonObject(with: webSocket.payload) as? [String: Any]
            self[.webSocketEventType] = object?["type"] as? String
        default:
            self = ["Details": attachment.logDescription]
        }
    }
}

extension LogEntry.Level {
    init(_ level: LogLevel) {
        switch level {
        case .debug: self = .debug
        case .info: self = .info
        case .warning: self = .warning
        case .error: self = .error
        }
    }
}

extension LogLevel {
    init(_ level: LogEntry.Level) {
        switch level {
        case ..<LogEntry.Level.info: self = .debug
        case ..<LogEntry.Level.warning: self = .info
        case ..<LogEntry.Level.error: self = .warning
        default: self = .error
        }
    }
}
