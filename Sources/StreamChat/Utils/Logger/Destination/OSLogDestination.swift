//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import OSLog

/// A log destination that records logs in memory.
@available(iOSApplicationExtension 14.0, *)
public class OSLogDestination: BaseLogDestination {
    private static let streamChatSubsystem = "com.getstream.chat"

    private let databaseLogger = os.Logger(
        subsystem: streamChatSubsystem,
        category: "database"
    )

    private let httpRequestsLogger = os.Logger(
        subsystem: streamChatSubsystem,
        category: "httpRequests"
    )

    private let webSocketLogger = os.Logger(
        subsystem: streamChatSubsystem,
        category: "webSocket"
    )

    private let offlineSupportLogger = os.Logger(
        subsystem: streamChatSubsystem,
        category: "offlineSupport"
    )

    private let authenticationLogger = os.Logger(
        subsystem: streamChatSubsystem,
        category: "authentication"
    )

    private let audioPlaybackLogger = os.Logger(
        subsystem: streamChatSubsystem,
        category: "audioPlayback"
    )

    private let otherLogger = os.Logger(
        subsystem: streamChatSubsystem,
        category: "other"
    )

    override public func process(logDetails: LogDetails) {
        let logger: os.Logger
        switch logDetails.subsystems {
        case .database:
            logger = databaseLogger
        case .httpRequests:
            logger = httpRequestsLogger
        case .webSocket:
            logger = webSocketLogger
        case .offlineSupport:
            logger = offlineSupportLogger
        case .authentication:
            logger = authenticationLogger
        case .audioPlayback:
            logger = audioPlaybackLogger
        case .other:
            logger = otherLogger
        default:
            logger = otherLogger
        }

        switch logDetails.level {
        case .debug:
            logger.debug("\(logDetails.message, privacy: .public)")
        case .info:
            logger.info("\(logDetails.message, privacy: .public)")
        case .error:
            logger.error("\(logDetails.message, privacy: .public)")
        case .warning:
            logger.warning("\(logDetails.message, privacy: .public)")
        }
    }
}
