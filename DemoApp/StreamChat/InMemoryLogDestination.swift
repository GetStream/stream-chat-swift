//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamLogsUI

/// Records every log, regardless of `LogConfig.level` and `LogConfig.subsystems`, so it can be inspected in `LogListView`.
final class InMemoryLogDestination: BaseLogDestination, @unchecked Sendable {
    override func isEnabled(level: LogLevel, subsystems: LogSubsystem) -> Bool {
        InMemoryLogStore.shared.isRecording
    }

    override func process(logDetails: LogDetails) {
        InMemoryLogStore.shared.append(LogEntry(
            date: logDetails.date,
            level: LogEntry.Level(rawValue: logDetails.level.rawValue) ?? .debug,
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
