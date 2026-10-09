//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
@_exported import StreamLogsUI

extension LogViewer {
    /// Records the logs of StreamChat, so that they can be browsed in the log viewer.
    ///
    /// The logger then sends its logs to the console and to the log viewer, and each of them can be switched off,
    /// and given its own level and subsystems, in the log viewer settings.
    /// The console starts with the destination types, level, subsystems and format of `LogConfig`,
    /// so configure them before calling this method, and don't change them afterwards. Call it once, when the app launches.
    @MainActor
    public static func install() {
        install(
            subsystems: [
                .other,
                .database,
                .httpRequests,
                .webSocket,
                .offlineSupport,
                .authentication,
                .audioPlayback,
                .audioRecording
            ],
            settings: .shared
        )
    }

    @MainActor
    static func install(subsystems: [LogSubsystem], settings: LogSettings) {
        let consoleDestinationTypes = LogConfig.destinationTypes
        settings.availableLevels = [.debug, .info, .warning, .error]
        settings.availableSubsystems = subsystems.map(\.description)
        settings.setDefaults([
            LogDestinationSettings(
                id: LogViewerDestination.consoleID,
                name: "Console",
                level: LogEntry.Level(LogConfig.level),
                disabledSubsystems: Set(subsystems.filter { !LogConfig.subsystems.contains($0) }.map(\.description))
            ),
            LogDestinationSettings(id: LogViewerDestination.logViewerID, name: "Log Viewer", level: .debug)
        ])
        settings.apply { settings in
            LogConfig.destinations = settings.enabledDestinations.flatMap { destination in
                let types: [LogDestination.Type] = destination.id == LogViewerDestination.logViewerID
                    ? [LogViewerDestination.self]
                    : consoleDestinationTypes
                let enabledSubsystems = settings.enabledSubsystems(for: destination)
                // Logs of subsystems that are not listed in the settings are only kept when none is disabled.
                let logSubsystems = destination.disabledSubsystems.isEmpty
                    ? LogSubsystem.all
                    : LogSubsystem(subsystems.filter { enabledSubsystems.contains($0.description) })
                return types.map { type in
                    type.init(
                        identifier: LogConfig.identifier,
                        level: LogLevel(destination.level),
                        subsystems: logSubsystems,
                        showDate: LogConfig.showDate,
                        dateFormatter: LogConfig.dateFormatter,
                        formatters: LogConfig.formatters,
                        showLevel: LogConfig.showLevel,
                        showIdentifier: LogConfig.showIdentifier,
                        showThreadName: LogConfig.showThreadName,
                        showFileName: LogConfig.showFileName,
                        showLineNumber: LogConfig.showLineNumber,
                        showFunctionName: LogConfig.showFunctionName
                    )
                }
            }
        }
    }
}
