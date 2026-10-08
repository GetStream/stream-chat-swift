//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatLogsUI

@MainActor
enum DemoAppLogging {
    static func setUp() {
        LogConfig.level = StreamRuntimeCheck.logLevel ?? .error
        LogConfig.formatters = [
            PrefixLogFormatter(prefixes: [.info: "ℹ️", .debug: "🛠", .warning: "⚠️", .error: "🚨"])
        ]
        if let subsystems = StreamRuntimeCheck.subsystems {
            LogConfig.subsystems = subsystems
        }

        LogViewer.install()
        LogViewer.defaultFilter = LogFilter(
            levels: [.debug],
            subsystems: Set([LogSubsystem.webSocket, .httpRequests].map(\.description))
        )
        LogViewer.presentsOnShake = true
    }
}
