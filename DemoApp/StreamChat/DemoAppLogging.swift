//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamLogsUI

@MainActor
enum DemoAppLogging {
    private static let subsystems: [LogSubsystem] = [
        .other,
        .database,
        .httpRequests,
        .webSocket,
        .offlineSupport,
        .authentication,
        .audioPlayback,
        .audioRecording
    ]

    static func setUp() {
        LogConfig.formatters = [
            PrefixLogFormatter(prefixes: [.info: "ℹ️", .debug: "🛠", .warning: "⚠️", .error: "🚨"])
        ]

        let settings = LogSettings.shared
        settings.availableLevels = [.debug, .info, .warning, .error]
        settings.availableSubsystems = subsystems.map(\.description)
        settings.setDefaults(
            level: LogEntry.Level(StreamRuntimeCheck.logLevel ?? .warning),
            disabledSubsystems: Set(
                subsystems
                    .filter { subsystem in StreamRuntimeCheck.subsystems.map { !$0.contains(subsystem) } ?? false }
                    .map(\.description)
            )
        )
        settings.apply { settings in
            LogConfig.level = LogLevel(settings.level)
            LogConfig.subsystems = LogSubsystem(subsystems.filter { settings.enabledSubsystems.contains($0.description) })
            LogConfig.destinationTypes = settings.isEnabled ? [OSLogDestination.self, InMemoryLogDestination.self] : []
        }

        LogViewer.presentsOnShake = true
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
            subsystems: LogSubsystem.allCases.filter { logDetails.subsystem.contains($0) }.map(\.description),
            threadName: logDetails.threadName,
            functionName: logDetails.functionName,
            fileName: logDetails.fileName,
            lineNumber: logDetails.lineNumber,
            message: logDetails.message,
            error: logDetails.error
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
