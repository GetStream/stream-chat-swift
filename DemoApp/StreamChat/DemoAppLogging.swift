//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamLogsUI

@MainActor
enum DemoAppLogging {
    private static let consoleID = "console"
    private static let logViewerID = "logViewer"

    // The subsystems used by Chat. The others are only used by Video.
    fileprivate nonisolated static let subsystems: [LogSubsystem] = [
        .other,
        .database,
        .httpRequests,
        .webSocket,
        .offlineSupport,
        .authentication,
        .audioPlayback,
        .audioRecording
    ]

    private static let formatters: [LogFormatter] = [
        PrefixLogFormatter(prefixes: [.info: "ℹ️", .debug: "🛠", .warning: "⚠️", .error: "🚨"])
    ]

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    static func setUp() {
        let settings = LogSettings.shared
        settings.availableLevels = [.debug, .info, .warning, .error]
        settings.availableSubsystems = subsystems.map(\.description)
        settings.setDefaults([
            LogDestinationSettings(
                id: consoleID,
                name: "Console",
                level: LogEntry.Level(StreamRuntimeCheck.logLevel ?? .error),
                disabledSubsystems: Set(
                    subsystems
                        .filter { subsystem in StreamRuntimeCheck.subsystems.map { !$0.contains(subsystem) } ?? false }
                        .map(\.description)
                )
            ),
            LogDestinationSettings(id: logViewerID, name: "Log Viewer", level: .debug)
        ])
        settings.apply { settings in
            LogConfig.destinations = settings.enabledDestinations.map { makeDestination($0, settings: settings) }
        }

        LogViewer.defaultFilter = LogFilter(
            levels: [.debug],
            subsystems: Set([LogSubsystem.webSocket, .httpRequests].map(\.description))
        )
        LogViewer.presentsOnShake = true
    }

    private static func makeDestination(_ destination: LogDestinationSettings, settings: LogSettings) -> LogDestination {
        let type: BaseLogDestination.Type = destination.id == logViewerID ? InMemoryLogDestination.self : OSLogDestination.self
        let enabledSubsystems = settings.enabledSubsystems(for: destination)
        return type.init(
            identifier: destination.id,
            level: LogLevel(destination.level),
            // Logs of subsystems that are not listed in the settings are only kept when none is disabled.
            subsystems: destination.disabledSubsystems.isEmpty
                ? .all
                : LogSubsystem(subsystems.filter { enabledSubsystems.contains($0.description) }),
            showDate: true,
            dateFormatter: dateFormatter,
            formatters: formatters,
            showLevel: true,
            showIdentifier: false,
            showThreadName: true,
            showFileName: true,
            showLineNumber: true,
            showFunctionName: true
        )
    }
}

final class InMemoryLogDestination: BaseLogDestination, @unchecked Sendable {
    override func isEnabled(level: LogLevel, subsystems: LogSubsystem) -> Bool {
        InMemoryLogStore.shared.isRecording && super.isEnabled(level: level, subsystems: subsystems)
    }

    override func process(logDetails: LogDetails) {
        InMemoryLogStore.shared.append(LogEntry(
            date: logDetails.date,
            level: LogEntry.Level(logDetails.level),
            subsystems: DemoAppLogging.subsystems.filter { logDetails.subsystem.contains($0) }.map(\.description),
            threadName: logDetails.threadName,
            functionName: logDetails.functionName,
            fileName: logDetails.fileName,
            lineNumber: logDetails.lineNumber,
            message: logDetails.message,
            error: logDetails.error,
            metadata: Dictionary(uniqueKeysWithValues: logDetails.metadata.map { key, value in
                (LogEntry.MetadataKey(rawValue: key.rawValue), value)
            })
        ))
    }
}

private extension LogEntry.Level {
    init(_ level: LogLevel) {
        switch level {
        case .debug: self = .debug
        case .info: self = .info
        case .warning: self = .warning
        case .error: self = .error
        }
    }
}

private extension LogLevel {
    init(_ level: LogEntry.Level) {
        switch level {
        case ..<LogEntry.Level.info: self = .debug
        case ..<LogEntry.Level.warning: self = .info
        case ..<LogEntry.Level.error: self = .warning
        default: self = .error
        }
    }
}
